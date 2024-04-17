import { initializeApp } from "https://www.gstatic.com/firebasejs/10.4.0/firebase-app.js";
import {
  getFirestore,
  collection,
  addDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.4.0/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyDzfXWTIOf5y7qtNDmAG0oObYdnjyG-Svw",
  authDomain: "swit-91d08.firebaseapp.com",
  databaseURL: "https://swit-91d08-default-rtdb.firebaseio.com",
  projectId: "swit-91d08",
  storageBucket: "swit-91d08.appspot.com",
  messagingSenderId: "259369139585",
  appId: "1:259369139585:web:e360f5e4e1b30daf373c80",
  measurementId: "G-YL5DVD5BJQ",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export async function addContacts(name, email, subject, content) {
  await addDoc(collection(db, "contacts"), {
    uid: null,
    name: name,
    email: email,
    subject: parseInt(subject, 10),
    content: content,
    credt: serverTimestamp(),
  });
}
