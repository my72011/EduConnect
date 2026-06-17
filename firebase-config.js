import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-firestore.js";

const firebaseConfig = {
    apiKey: "AIzaSyDHwekj7CKJnBuZq2lAhX2rESGedNH_Euc",
    authDomain: "educonnect-36179.firebaseapp.com",
    projectId: "educonnect-36179",
    storageBucket: "educonnect-36179.firebasestorage.app",
    messagingSenderId: "464703951825",
    appId: "1:464703951825:web:7a2241ecce2f3e108d46f0",
    measurementId: "G-L2WTT0Q878"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

export { auth, db };
