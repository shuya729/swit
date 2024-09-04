const https = require("https");
const { initializeApp } = require("firebase-admin/app");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getDatabase } = require("firebase-admin/database");
const { getMessaging } = require("firebase-admin/messaging");
const { user } = require("firebase-functions/v1/auth");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const {
  onValueCreated,
  onValueUpdated,
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

  // 後で削除
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

  const myFriendsRef = firestore
    .collection("users")
    .doc(user.uid)
    .collection("friends");
  const myFriendsDocs = await myFriendsRef.get();

  const logsRef = firestore
    .collection("users")
    .doc(user.uid)
    .collection("logs");
  const logsDocs = await logsRef.get();

  const batch = firestore.batch();

  // 後で削除
  if (!statesDocs.empty) {
    statesDocs.forEach((doc) => {
      batch.update(doc.ref, { [user.uid]: FieldValue.delete() });
    });
  }

  if (!myFriendsDocs.empty) {
    myFriendsDocs.forEach((doc) => {
      batch.delete(doc.ref);
      const tgtFriendRef = firestore
        .collection("users")
        .doc(doc.id)
        .collection("friends")
        .doc(user.uid);
      batch.delete(tgtFriendRef);
    });
  }

  if (!logsDocs.empty) {
    logsDocs.forEach((doc) => {
      batch.delete(doc.ref);
    });
  }

  const friendsRef = firestore.collection("friends").doc(user.uid);
  batch.delete(friendsRef);

  const tokenRef = firestore.collection("tokens").doc(user.uid);
  batch.delete(tokenRef);

  await batch.commit();

  const iconImage = storage.bucket().file(`users/${user.uid}/iconImage.jpg`);
  if (iconImage.exists()) {
    await storage.bucket().file(`users/${user.uid}/iconImage.jpg`).delete();
  }
});

exports.friendMessageFunction = onDocumentWritten(
  {
    document: "users/{userId}/friends/{friendId}",
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    timeoutSeconds: 10,
  },
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData) {
      const uid = afterData.uid;
      const tgt = afterData.tgt;
      const state = afterData.state;

      if (state === "requesting") await toMessaging(uid, tgt, "request");
    } else if (!afterData) {
      const uid = beforeData.uid;
      const tgt = beforeData.tgt;
      const state = beforeData.state;

      if (state === "requesting") {
        const ref = firestore
          .collection("messages")
          .doc(uid + "-" + tgt + "-" + "request");
        await ref.delete();
      }
    } else {
      const uid = beforeData.uid;
      const tgt = beforeData.tgt;
      const beforeState = beforeData.state;
      const afterState = afterData.state;

      if (beforeState === "requested" && afterState === "friend") {
        await toMessaging(uid, tgt, "friend");
      }
    }

    // 後で削除
    // 反映されていない場合、追加
    firestore.runTransaction(async (t) => {
      if (!beforeData) {
        const uid = afterData.uid;
        const tgt = afterData.tgt;
        const state = afterData.state;
        const ref = firestore.collection("friends").doc(uid);
        const doc = await t.get(ref);
        if (!doc.exists || doc.data()[tgt] !== state) {
          t.set(ref, { [tgt]: state }, { merge: true });
        }
      } else if (!afterData) {
        const uid = beforeData.uid;
        const tgt = beforeData.tgt;
        const state = beforeData.state;
        const ref = firestore.collection("friends").doc(uid);
        const doc = await t.get(ref);
        if (doc.exists && doc.data()[tgt]) {
          t.set(ref, { [tgt]: FieldValue.delete() }, { merge: true });
        }
      } else {
        const uid = beforeData.uid;
        const tgt = beforeData.tgt;
        const afterState = afterData.state;
        const ref = firestore.collection("friends").doc(uid);
        const doc = await t.get(ref);
        if (doc.exists && doc.data()[tgt] !== afterState) {
          t.set(ref, { [tgt]: afterState }, { merge: true });
        }
      }
    });
  }
);

// 後で削除
exports.requestFunction = onDocumentCreated(
  {
    document: "requests/{requestId}",
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    minInstances: 1,
    timeoutSeconds: 10,
  },
  async (event) => {
    const data = event.data.data();

    const uid = data.uid;
    const tgt = data.tgt;
    const request = data.request;

    const sourceRef = event.data.ref;
    const myFriendRef = firestore.collection("friends").doc(uid);
    const ufriendsRef = firestore
      .collection("users")
      .doc(uid)
      .collection("friends")
      .doc(tgt);
    const tgtFriendRef = firestore.collection("friends").doc(tgt);
    const tfriendsRef = firestore
      .collection("users")
      .doc(tgt)
      .collection("friends")
      .doc(uid);

    await firestore.runTransaction(async (t) => {
      const sourceDoc = await t.get(sourceRef);
      if (!sourceDoc.exists) return;
      const tgtFriendDoc = await t.get(tgtFriendRef);

      if (request === "friend") {
        if (
          tgtFriendDoc.exists &&
          (tgtFriendDoc.data()[uid] === "friend" ||
            tgtFriendDoc.data()[uid] === "requested")
        ) {
        } else if (
          tgtFriendDoc.exists &&
          tgtFriendDoc.data()[uid] === "requesting"
        ) {
          t.set(tgtFriendRef, { [uid]: "friend" }, { merge: true });
          t.set(myFriendRef, { [tgt]: "friend" }, { merge: true });
          t.set(
            ufriendsRef,
            {
              uid: uid,
              tgt: tgt,
              state: "friend",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          t.set(
            tfriendsRef,
            {
              uid: tgt,
              tgt: uid,
              state: "friend",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          // await messaging(uid, [tgt], "friend");
        } else {
          t.set(tgtFriendRef, { [uid]: "requested" }, { merge: true });
          t.set(myFriendRef, { [tgt]: "requesting" }, { merge: true });
          t.set(
            ufriendsRef,
            {
              uid: uid,
              tgt: tgt,
              state: "requesting",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          t.set(
            tfriendsRef,
            {
              uid: tgt,
              tgt: uid,
              state: "requested",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          // await messaging(uid, [tgt], "request");
        }
      } else if (request === "unfriend") {
        t.set(tgtFriendRef, { [uid]: FieldValue.delete() }, { merge: true });
        t.set(myFriendRef, { [tgt]: FieldValue.delete() }, { merge: true });
        t.delete(ufriendsRef);
        t.delete(tfriendsRef);
      } else if (request === "block") {
        if (tgtFriendDoc.exists && tgtFriendDoc.data()[uid] === "blocking") {
          t.set(myFriendRef, { [tgt]: "blocking" }, { merge: true });
          t.set(
            ufriendsRef,
            {
              uid: uid,
              tgt: tgt,
              state: "blocking",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        } else {
          t.set(tgtFriendRef, { [uid]: "blocked" }, { merge: true });
          t.set(myFriendRef, { [tgt]: "blocking" }, { merge: true });
          t.set(
            ufriendsRef,
            {
              uid: uid,
              tgt: tgt,
              state: "blocking",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          t.set(
            tfriendsRef,
            {
              uid: tgt,
              tgt: uid,
              state: "blocked",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      } else if (request === "unblock") {
        if (tgtFriendDoc.exists && tgtFriendDoc.data()[uid] === "blocking") {
          t.set(myFriendRef, { [tgt]: "blocked" }, { merge: true });
          t.set(
            ufriendsRef,
            {
              uid: uid,
              tgt: tgt,
              state: "blocked",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        } else {
          t.set(tgtFriendRef, { [uid]: "friend" }, { merge: true });
          t.set(myFriendRef, { [tgt]: "friend" }, { merge: true });
          t.set(
            ufriendsRef,
            {
              uid: uid,
              tgt: tgt,
              state: "friend",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          t.set(
            tfriendsRef,
            {
              uid: tgt,
              tgt: uid,
              state: "friend",
              upddt: FieldValue.serverTimestamp(),
              credt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
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
    minInstances: 1,
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

exports.studyingFunction = onValueUpdated(
  {
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    ref: "/presence/{presenceId}",
    timeoutSeconds: 10,
  },
  async (event) => {
    const uid = event.data.after.val().uid;
    const credt = event.data.after.val().credt;
    const upddt = event.data.after.val().upddt;
    const hour = 60 * 60 * 1000;

    if (upddt > credt + hour) return;

    const snapshot = await firestore
      .collection("users")
      .doc(uid)
      .collection("friends")
      .get();

    if (snapshot.empty) return;

    const tgts = snapshot.docs.map((doc) => doc.id);
    if (tgts.length === 0) return;

    await messaging(uid, tgts, "studing");
  }
);

exports.logFunction = onValueDeleted(
  {
    concurrency: 50,
    cpu: 1,
    memory: "256MiB",
    minInstances: 1,
    ref: "/presence/{presenceId}",
    timeoutSeconds: 10,
  },
  async (event) => {
    const uid = event.data.val().uid;
    const upd = new Date(event.data.val().upddt);
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

    let logs;
    if (upd.getTime() >= now.getTime() - baseTime) {
      const end = min ?? now;
      logs = calcLogs(bgn, end);
    } else {
      logs = calcLogs(bgn, upd);
    }
    if (Object.keys(logs).length === 0) return;
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

// 後で削除
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
  if (bgn.getTime() >= now.getTime()) return {};
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

async function toMessaging(uid, tgt, type) {
  const ref = firestore
    .collection("messages")
    .doc(uid + "-" + tgt + "-" + type);
  await ref.set({
    uid: uid,
    tgt: tgt,
    type: type,
    upddt: FieldValue.serverTimestamp(),
  });
  await messaging(uid, [tgt], type);
}

async function messaging(uid, tgts, type) {
  const now = new Date().getTime();
  const baseTime = 30 * 24 * 60 * 60 * 1000;
  const tokens = [];
  const failed = [];
  const ntfCounts = {};

  if (!Array.isArray(tgts)) return;
  const snapshot = await firestore
    .collection("tokens")
    .where("uid", "in", tgts)
    .get();
  if (snapshot.empty) return;

  const messages = await firestore
    .collection("messages")
    .where("tgt", "in", tgts)
    .get();

  snapshot.forEach((doc) => {
    Object.keys(doc.data()).forEach((key) => {
      if (key === "uid") return;
      const val = doc.data()[key];
      if (val instanceof Timestamp && val.toMillis() > now - baseTime) {
        tokens.push(key);
        ntfCounts[key] = messages.docs.filter(
          (ntfdoc) => ntfdoc.data().tgt === doc.id
        ).length;
      } else {
        failed.push(key);
      }
    });
  });

  if (tokens.length > 0) {
    const userDoc = await firestore.collection("users").doc(uid).get();
    if (!userDoc.exists) return;
    const userName = userDoc.data().name;

    let title = "";
    let body = "";
    if (type === "request") {
      title = "フレンドリクエスト";
      body = `${userName} からフレンドリクエストが届いています`;
    } else if (type === "friend") {
      title = "リクエスト承認";
      body = `${userName} とフレンドになりました`;
    } else if (type === "studing") {
      title = "SWiT Study";
      body = `${userName} がSWiTで勉強しています`;
    }
    if (title === "" || body === "") return;

    const messages = [];
    tokens.forEach((token) => {
      messages.push({
        token: token,
        notification: {
          title: title,
          body: body,
        },
        android: {
          notification: {
            // notification_count: ntfCounts[token], // 後でコメント外す
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              // badge: ntfCounts[token], // 後でコメント外す
              sound: "default",
            },
          },
        },
      });
    });
    const ret = await getMessaging().sendEach(messages);

    if (ret.failureCount > 0) {
      ret.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failed.push(tokens[idx]);
        }
      });
    }
  }
  if (failed.length === 0) return;

  const batch = firestore.batch();
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const tgtTokens = failed.filter((key) => data[key]);
    if (tgtTokens.length === 0) return;
    const tgtTokenRef = firestore.collection("tokens").doc(data.uid);
    const tgtData = {};
    tgtTokens.forEach((key) => {
      tgtData[key] = FieldValue.delete();
    });
    batch.update(tgtTokenRef, tgtData);
  });
  await batch.commit();
}

// const { onRequest } = require("firebase-functions/v2/https");
// exports.testFunction = onRequest(async (req, res) => {
//   // const uid = req.query.uid ?? "3672Q3SJxUNCDhHeLQRThmUa9vj1";
//   const friendsRef = firestore.collection("friends");
//   const friendsDocs = await friendsRef.get();
//   const batch = firestore.batch();
//   friendsDocs.forEach((doc) => {
//     const uid = doc.id;
//     const data = doc.data();
//     Object.keys(data).forEach((key) => {
//       const ref = firestore
//         .collection("users")
//         .doc(uid)
//         .collection("friends")
//         .doc(key);
//       const tgt = key;
//       const state = data[key];
//       batch.set(ref, {
//         uid: uid,
//         tgt: tgt,
//         state: state,
//         upddt: FieldValue.serverTimestamp(),
//         credt: FieldValue.serverTimestamp(),
//       });
//     });
//   });
//   await batch.commit();
//   res.send("ok");
// });
