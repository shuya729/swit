const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getDatabase } = require("firebase-admin/database");
const { user } = require("firebase-functions/v1/auth");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const {
  onValueCreated,
  onValueDeleted,
} = require("firebase-functions/v2/database");

initializeApp();

const timezone = "Asia/Tokyo";
process.env.TZ = timezone;

const firestore = getFirestore();
const storage = getStorage();
const database = getDatabase();

exports.createFunction = user().onCreate(async (user) => {
  const now = new Date();
  await firestore
    .collection("users")
    .doc(user.uid)
    .set({
      uid: user.uid,
      image: user.photoURL ? user.photoURL : "",
      name: user.displayName ? user.displayName : "",
      bgndt: now,
      upddt: now,
      credt: now,
    });
});

exports.deleteFunction = user().onDelete(async (user) => {
  const userRef = firestore.collection("users").doc(user.uid);
  await userRef.delete();

  const statesQuery = firestore
    .collection("friends")
    .where(user.uid, "in", [
      "friend",
      "requesting",
      "requested",
      "blocked",
      "blocking",
    ]);
  const statesDocs = await statesQuery.get();

  const logsRef = firestore
    .collection("users")
    .doc(user.uid)
    .collection("logs");
  const logsDocs = await logsRef.get();

  const batch = firestore.batch();

  if (!statesDocs.empty) {
    statesDocs.forEach((doc) => {
      batch.update(doc.ref, { [user.uid]: FieldValue.delete() });
    });
  }

  if (!logsDocs.empty) {
    logsDocs.forEach((doc) => {
      batch.delete(doc.ref);
    });
  }

  const friendsRef = firestore.collection("friends").doc(user.uid);
  batch.delete(friendsRef);

  await batch.commit();

  const iconImage = storage.bucket().file(`users/${user.uid}/iconImage.jpg`);
  if (iconImage.exists()) {
    await storage.bucket().file(`users/${user.uid}/iconImage.jpg`).delete();
  }

  const databaseRef = database.ref(`users/${user.uid}`);
  await databaseRef.remove();
});

exports.requestFunction = onDocumentCreated(
  "requests/{requestId}",
  async (event) => {
    const data = event.data.data();
    const requestId = event.params.requestId;

    const uid = data.uid;
    const tgt = data.tgt;
    const request = data.request;

    const sourceRef = firestore.collection("requests").doc(requestId);
    const myFriendRef = firestore.collection("friends").doc(uid);
    const tgtFriendRef = firestore.collection("friends").doc(tgt);

    firestore
      .runTransaction(async (t) => {
        const sourceDoc = await t.get(sourceRef);
        if (!sourceDoc.exists) return;
        const tgtFriendDoc = await t.get(tgtFriendRef);

        if (request === "friend") {
          if (
            tgtFriendDoc.exists &&
            tgtFriendDoc.data()[uid] === "requesting"
          ) {
            t.set(tgtFriendRef, { [uid]: "friend" }, { merge: true });
            t.set(myFriendRef, { [tgt]: "friend" }, { merge: true });
          } else {
            t.set(tgtFriendRef, { [uid]: "requested" }, { merge: true });
            t.set(myFriendRef, { [tgt]: "requesting" }, { merge: true });
          }
        } else if (request === "unfriend") {
          t.set(tgtFriendRef, { [uid]: FieldValue.delete() }, { merge: true });
          t.set(myFriendRef, { [tgt]: FieldValue.delete() }, { merge: true });
        } else if (request === "block") {
          if (tgtFriendDoc.exists && tgtFriendDoc.data()[uid] === "blocking") {
            t.set(myFriendRef, { [tgt]: "blocking" }, { merge: true });
          } else {
            t.set(tgtFriendRef, { [uid]: "blocked" }, { merge: true });
            t.set(myFriendRef, { [tgt]: "blocking" }, { merge: true });
          }
        } else if (request === "unblock") {
          if (tgtFriendDoc.exists && tgtFriendDoc.data()[uid] === "blocking") {
            t.set(myFriendRef, { [tgt]: "blocked" }, { merge: true });
          } else {
            t.set(tgtFriendRef, { [uid]: "friend" }, { merge: true });
            t.set(myFriendRef, { [tgt]: "friend" }, { merge: true });
          }
        }
      })
      .then(() => {
        sourceRef.delete();
      });
  }
);

exports.presenceFunction = onValueCreated(
  "/users/{uid}/{conId}",
  async (event) => {
    const uid = event.params.uid;
    const now = new Date();
    const userRef = firestore.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) return;
    const bgndt = userDoc.data().bgndt;
    if (bgndt === null) {
      userRef.update({ bgndt: now, upddt: now });
      return;
    }
    const snapshot = await event.data.ref.parent
      .orderByValue()
      .startAt(now.getTime() - 4000000)
      .get();
    if (!snapshot.exists() || snapshot.numChildren() > 1) return;
    userRef.update({ bgndt: now, upddt: now });
  }
);

exports.logFunction = onValueDeleted("/users/{uid}/{conId}", async (event) => {
  const uid = event.params.uid;
  const now = new Date();
  const userRef = firestore.collection("users").doc(uid);
  const snapshot = await event.data.ref.parent
    .orderByValue()
    .startAt(now.getTime() - 4000000)
    .get();
  if (snapshot.exists()) return;
  const userDoc = await userRef.get();
  if (!userDoc.exists) return;
  const bgndt = userDoc.data().bgndt;
  if (bgndt === null) return;
  userRef.update({ bgndt: null, upddt: now });

  const bgn = bgndt.toDate();
  const logs = calcLogs(bgn, now);
  const batch = firestore.batch();
  Object.keys(logs).forEach((key) => {
    const logRef = firestore
      .collection("users")
      .doc(uid)
      .collection("logs")
      .doc(key);
    batch.set(logRef, logs[key], { merge: true });
  });
  await batch.commit();

  function getMonthKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    return `${year}-${month}`;
  }

  function getDateKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }

  function calcLogs(bgn, now) {
    if (bgn.getTime() > now.getTime()) return {};
    if (
      bgn.getFullYear() !== now.getFullYear() ||
      bgn.getMonth() !== now.getMonth() ||
      bgn.getDate() !== now.getDate()
    ) {
      const monthKey = getMonthKey(bgn);
      const dateKey = getDateKey(bgn);
      const baseDate = new Date(
        bgn.getFullYear(),
        bgn.getMonth(),
        bgn.getDate() + 1
      );
      const diff = baseDate.getTime() - bgn.getTime();
      return {
        [monthKey]: {
          monthKey: monthKey,
          [dateKey]: FieldValue.increment(diff),
        },
        ...calcLogs(baseDate, now),
      };
    } else {
      const monthKey = getMonthKey(bgn);
      const dateKey = getDateKey(bgn);
      const diff = now.getTime() - bgn.getTime();
      return {
        [monthKey]: {
          monthKey: monthKey,
          [dateKey]: FieldValue.increment(diff),
        },
      };
    }
  }
});
