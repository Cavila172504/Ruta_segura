require('dotenv').config({ path: '.env.local' });
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function loadServiceAccount() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
  if (inline) {
    const parsed = JSON.parse(inline);
    if (parsed.private_key) parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
    return parsed;
  }

  const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  if (filePath) {
    const absolute = path.isAbsolute(filePath) ? filePath : path.join(__dirname, '..', filePath);
    const parsed = JSON.parse(fs.readFileSync(absolute, 'utf8'));
    if (parsed.private_key) parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
    return parsed;
  }

  return null;
}

let credentialInfo;
try {
  credentialInfo = loadServiceAccount();
  if (!credentialInfo) throw new Error('Sin credenciales');
} catch (e) {
  console.error('Define FIREBASE_SERVICE_ACCOUNT o FIREBASE_SERVICE_ACCOUNT_PATH en .env.local');
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(credentialInfo) });

const db = admin.firestore();
const auth = admin.auth();

async function createAdmin() {
  const email = process.env.SCHOOL_ADMIN_EMAIL?.trim();
  const password = process.env.SCHOOL_ADMIN_PASSWORD?.trim();
  const name = process.env.SCHOOL_ADMIN_NAME?.trim() || 'Administrador';
  const unitCode = process.env.SCHOOL_UNIT_CODE?.trim().toUpperCase() || 'CAD31';

  if (!email || !password || password.length < 8) {
    console.error('Define SCHOOL_ADMIN_EMAIL y SCHOOL_ADMIN_PASSWORD (min. 8 caracteres) en .env.local');
    process.exit(1);
  }

  try {
    console.log(`Creando o actualizando usuario Auth para ${email}...`);
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      await auth.updateUser(userRecord.uid, { displayName: name, password });
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      userRecord = await auth.createUser({ email, password, displayName: name });
    }

    await db.collection('users').doc('admins').collection('members').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email,
      name,
      role: 'admin',
      unitCode,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log('Administrador creado o actualizado exitosamente.');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createAdmin();