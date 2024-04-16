const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getDatabase } = require("firebase-admin/database");
const { user } = require("firebase-functions/v1/auth");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onValueUpdated } = require("firebase-functions/v2/database");

initializeApp();

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
  const statesQuery = firestore
    .collection("friends")
    .where(user.uid, "in", [
      "friend",
      "requesting",
      "requested",
      "blocked",
      "blocking",
    ]);
  await firestore.runTransaction(async (t) => {
    const statesDocs = await t.get(statesQuery);
    if (!statesDocs.empty) {
      statesDocs.forEach((doc) => {
        t.update(doc.ref, { [user.uid]: FieldValue.delete() });
      });
    }
  });

  const friendsRef = firestore.collection("friends").doc(user.uid);
  await friendsRef.delete();

  const batch = firestore.batch();
  const logsRef = firestore
    .collection("users")
    .doc(user.uid)
    .collection("logs");
  const logsDocs = await logsRef.get();
  if (!logsDocs.empty) {
    logsDocs.forEach((doc) => {
      batch.delete(doc.ref);
    });
  }
  await batch.commit();

  const userRef = firestore.collection("users").doc(user.uid);
  await userRef.delete();

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

exports.presenceFunction = onValueUpdated("/users/{uid}", async (event) => {
  const uid = event.params.uid;
  const before = event.data.before.val();
  const after = event.data.after.val();

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

  if (before === after) return;

  const now = new Date();
  const userRef = firestore.collection("users").doc(uid);

  if (before === false && after === true) {
    await userRef.update({ bgndt: now, upddt: now });
  } else if (before === true && after === false) {
    firestore.runTransaction(async (t) => {
      const userDoc = await t.get(userRef);
      const bgndt = userDoc.data().bgndt;

      if (bgndt === null) return;
      t.update(userRef, { bgndt: null, upddt: now });

      const bgn = bgndt.toDate();
      const diff = now.getTime() - bgn.getTime();
      if (diff < 0 || 24 * 60 * 60 * 1000 < diff) return;

      if (now.getMonth !== bgn.getMonth) {
        const nowMonthKey = getMonthKey(now);
        const bgnMonthKey = getMonthKey(bgn);
        const nowDateKey = getDateKey(now);
        const bgnDateKey = getDateKey(bgn);
        const nowDiff =
          now.getTime() -
          new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
        const bgnDiff =
          new Date(bgn.getFullYear(), bgn.getMonth(), bgn.getDate()).getTime() -
          bgn.getTime();
        t.set(
          firestore
            .collection("users")
            .doc(uid)
            .collection("logs")
            .doc(nowMonthKey),
          {
            monthKey: nowMonthKey,
            [nowDateKey]: FieldValue.increment(nowDiff),
          },
          { merge: true }
        );
        t.set(
          firestore
            .collection("users")
            .doc(uid)
            .collection("logs")
            .doc(bgnMonthKey),
          {
            monthKey: bgnMonthKey,
            [bgnDateKey]: FieldValue.increment(bgnDiff),
          },
          { merge: true }
        );
      } else if (now.getDate !== bgn.getDate) {
        const monthKey = getMonthKey(now);
        const nowDateKey = getDateKey(now);
        const bgnDateKey = getDateKey(bgn);
        const nowDiff =
          now.getTime() -
          new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
        const bgnDiff =
          new Date(bgn.getFullYear(), bgn.getMonth(), bgn.getDate()).getTime() -
          bgn.getTime();
        t.set(
          firestore
            .collection("users")
            .doc(uid)
            .collection("logs")
            .doc(monthKey),
          {
            monthKey: monthKey,
            [nowDateKey]: FieldValue.increment(nowDiff),
            [bgnDateKey]: FieldValue.increment(bgnDiff),
          },
          { merge: true }
        );
      } else {
        const monthKey = getMonthKey(now);
        const dateKey = getDateKey(now);
        t.set(
          firestore
            .collection("users")
            .doc(uid)
            .collection("logs")
            .doc(monthKey),
          { monthKey: monthKey, [dateKey]: FieldValue.increment(diff) },
          { merge: true }
        );
      }
    });
  }
});
