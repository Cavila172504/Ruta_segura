import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyD8V9qrjc4oXPHN5fO1_r1ieSAKDp0S_KY",
  authDomain: "rutasegura-a74f7.firebaseapp.com",
  projectId: "rutasegura-a74f7",
  storageBucket: "rutasegura-a74f7.firebasestorage.app",
  messagingSenderId: "706491407166",
  appId: "1:706491407166:web:f1e908d7d3406570036a6f"
};

// Initialize Firebase
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

export { auth, db, storage };
