const https = require("https");
const { initializeApp } = require("firebase-admin/app");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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
});

exports.requestFunction = onDocumentCreated(
  {
    document: "requests/{requestId}",
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    // minInstances: 1,
    timeoutSeconds: 10,
  },
  async (event) => {
    const data = event.data.data();

    const uid = data.uid;
    const tgt = data.tgt;
    const request = data.request;

    const sourceRef = event.data.ref;
    const myFriendRef = firestore.collection("friends").doc(uid);
    const tgtFriendRef = firestore.collection("friends").doc(tgt);

    await firestore.runTransaction(async (t) => {
      const sourceDoc = await t.get(sourceRef);
      if (!sourceDoc.exists) return;
      const tgtFriendDoc = await t.get(tgtFriendRef);

      if (request === "friend") {
        if (tgtFriendDoc.exists && tgtFriendDoc.data()[uid] === "requesting") {
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
    });

    await sourceRef.delete();
  }
);

exports.presenceFunction = onValueCreated(
  {
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    // minInstances: 1,
    ref: "/presence/{presenceId}",
    timeoutSeconds: 10,
  },
  async (event) => {
    const uid = event.data.val().uid;
    const bgn = new Date(event.data.val().credt);
    const now = new Date();
    const baseTime = 60 * 60 * 1000;
    const userRef = firestore.collection("users").doc(uid);

    const snapshot = await event.data.ref.parent
      .orderByChild("uid")
      .equalTo(uid)
      .get();

    if (!snapshot.exists()) return;
    let mindt = bgn.getTime();
    snapshot.forEach((child) => {
      if (
        child.val().upddt > now.getTime() - baseTime &&
        child.val().credt < mindt
      ) {
        mindt = child.val().credt;
      }
    });
    if (mindt !== bgn.getTime()) return;

    userRef.update({ bgndt: bgn, upddt: now });
  }
);

exports.logFunction = onValueDeleted(
  {
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    // minInstances: 1,
    ref: "/presence/{presenceId}",
    timeoutSeconds: 10,
  },
  async (event) => {
    const uid = event.data.val().uid;
    const upddt = event.data.val().upddt;
    const bgn = new Date(event.data.val().credt);
    const now = new Date();
    const baseTime = 60 * 60 * 1000;
    const userRef = firestore.collection("users").doc(uid);

    const snapshot = await event.data.ref.parent
      .orderByChild("uid")
      .equalTo(uid)
      .get();

    let mindt = null;
    if (snapshot.exists()) {
      snapshot.forEach((child) => {
        if (
          child.val().upddt > now.getTime() - baseTime &&
          (mindt === null || child.val().credt < mindt)
        ) {
          mindt = child.val().credt;
        }
      });
    }
    const min = mindt ? new Date(mindt) : null;
    userRef.update({ bgndt: min, upddt: now });

    if (upddt < now.getTime() - baseTime) return;
    const end = min ?? now;
    const logs = calcLogs(bgn, end);
    const batch = firestore.batch();
    Object.keys(logs).forEach((key) => {
      const logRef = firestore
        .collection("users")
        .doc(uid)
        .collection("logs")
        .doc(key);
      batch.set(logRef, logs[key], { merge: true });
    });
    batch.commit();
  }
);

exports.presenceCroller = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: timezone,
    concurrency: 1,
    cpu: 1,
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const now = new Date();
    const baseTime = 60 * 60 * 1000;
    const query = database
      .ref("presence")
      .orderByChild("upddt")
      .endAt(now - baseTime)
      .limitToFirst(100);
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    console.log("delete presence num: ", snapshot.numChildren());

    let newData = {};
    snapshot.forEach((child) => {
      newData[child.key] = null;
    });

    database.ref("presence").update(newData);
  }
);

exports.requestCroller = onSchedule(
  {
    schedule: "30 * * * *",
    timeZone: timezone,
    concurrency: 1,
    cpu: 1,
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const now = new Date();
    const baseDate = new Date(now.getTime() - 15 * 60 * 1000);
    const query = firestore
      .collection("requests")
      .where("credt", "<", baseDate)
      .limit(100);
    const snapshot = await query.get();

    if (snapshot.empty) return;

    console.log("delete requests num: ", snapshot.size);

    const batch = firestore.batch();
    snapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });
    batch.commit();
  }
);

exports.contactFunction = onDocumentCreated(
  {
    document: "contacts/{contactId}",
    concurrency: 1,
    cpu: 0.083,
    memory: "128MiB",
    timeoutSeconds: 10,
  },
  async (event) => {
    const data = event.data.data();

    const id = event.params.contactId;
    const uid = data.uid ? data.uid : "";
    const name = data.name ? data.name : "";
    const email = data.email ? data.email : "";
    const subject = data.subject ? data.subject : 0;
    const content = data.content ? data.content : "";

    const subjectList = [
      "ご意見",
      "不具合報告",
      "アカウント削除申請",
      "その他",
    ];

    const message = `\n[swit Contact]\n\nID: ${id}\nuid:${uid}\nName: ${name}\nEmail: ${email}\nSubject: ${subjectList[subject]}\nContent: \n${content}`;

    const token = "B17yu5FnCELYOynkHLFVYBfrm38lrVICl7j9cwQZ6sB";
    const options = {
      hostname: "notify-api.line.me",
      path: "/api/notify",
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Bearer ${token}`,
      },
    };
    const request = https.request(options, (res) => res.setEncoding("utf8"));
    request.write(new URLSearchParams({ message: message }).toString());
    request.end();
  }
);

// 以下、使用する関数
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
    const nextLogs = calcLogs(baseDate, now);
    const monthLogs = nextLogs[monthKey] ? nextLogs[monthKey] : {};
    return {
      ...nextLogs,
      [monthKey]: {
        monthKey: monthKey,
        ...monthLogs,
        [dateKey]: FieldValue.increment(diff),
      },
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

// const { onRequest } = require("firebase-functions/v2/https");
// exports.testFunction = onRequest(async (req, res) => {

//   res.send("ok");
// });
