const { initializeApp } = require("firebase/app");
const { getAuth, createUserWithEmailAndPassword } = require("firebase/auth");
const { getFirestore, doc, setDoc } = require("firebase/firestore");

const firebaseConfig = {
  apiKey: "AIzaSyD8V9qrjc4oXPHN5fO1_r1ieSAKDp0S_KY",
  authDomain: "rutasegura-a74f7.firebaseapp.com",
  projectId: "rutasegura-a74f7",
  storageBucket: "rutasegura-a74f7.firebasestorage.app",
  messagingSenderId: "706491407166",
  appId: "1:706491407166:web:f1e908d7d3406570036a6f"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function createAdmin() {
  const email = "deyafreiresalazar@gmail.com";
  const password = "12345678";

  try {
    console.log(`Creando usuario Auth para ${email}...`);
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const uid = userCredential.user.uid;
    console.log(`Usuario creado con UID: ${uid}`);

    console.log("Creando documento de perfil en Firestore...");
    await setDoc(doc(db, "users", "admins", "members", uid), {
      uid: uid,
      email: email,
      name: "Deya Freire",
      role: "admin",
      unitCode: "MDE0", // Colegio CADE
      createdAt: new Date().toISOString()
    });

    console.log("¡Administrador creado exitosamente!");
    process.exit(0);
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
        console.log("El usuario ya existe en Auth. Intentando actualizar perfil...");
        // Si ya existe, no podemos obtener el UID fácilmente sin Admin SDK o Login.
        // Pero el usuario ya puede intentar loguearse.
    } else {
        console.error("Error:", error.message);
    }
    process.exit(1);
  }
}

createAdmin();
