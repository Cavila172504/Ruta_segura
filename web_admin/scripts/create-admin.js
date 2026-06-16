const { initializeApp } = require("firebase/app");
const { getAuth, createUserWithEmailAndPassword } = require("firebase/auth");
const { getFirestore, doc, setDoc } = require("firebase/firestore");
const firebaseConfig = require("./firebase-client-config");

if (!firebaseConfig.apiKey) {
  console.error("Falta NEXT_PUBLIC_FIREBASE_API_KEY en web_admin/.env.local");
  process.exit(1);
}

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
