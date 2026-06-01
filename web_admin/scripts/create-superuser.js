require('dotenv').config({ path: '.env.local' });
const admin = require('firebase-admin');

let credentialInfo;
try {
  credentialInfo = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  if (credentialInfo.private_key) {
    credentialInfo.private_key = credentialInfo.private_key.replace(/\\n/g, '\n');
  }
} catch (e) {
  console.error('Define FIREBASE_SERVICE_ACCOUNT en .env.local (JSON válido).');
  process.exit(1);
}

const email = process.env.SUPER_ADMIN_EMAIL;
const password = process.env.SUPER_ADMIN_PASSWORD;
const name = process.env.SUPER_ADMIN_NAME || 'Super Admin';

if (!email || !password || password.length < 8) {
  console.error('Define SUPER_ADMIN_EMAIL y SUPER_ADMIN_PASSWORD (mín. 8 caracteres).');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(credentialInfo),
});

const db = admin.firestore();
const auth = admin.auth();

async function createSuperAdmin() {
  try {
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log('Usuario existente, actualizando contraseña...');
      await auth.updateUser(userRecord.uid, { password });
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await auth.createUser({
          email,
          password,
          displayName: name,
        });
        console.log('Usuario creado:', userRecord.uid);
      } else {
        throw e;
      }
    }

    await db
      .collection('users')
      .doc('super_admins')
      .collection('members')
      .doc(userRecord.uid)
      .set({
        uid: userRecord.uid,
        email,
        name,
        role: 'super_admin',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log('Super administrador listo:', email);
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

createSuperAdmin();
