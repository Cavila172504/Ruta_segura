require('dotenv').config({ path: '.env.local' });
const admin = require('firebase-admin');

let credentialInfo;
try {
  credentialInfo = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  if (credentialInfo.private_key) {
    credentialInfo.private_key = credentialInfo.private_key.replace(/\\n/g, '\n');
  }
} catch (e) {
  console.error("Error parsing FIREBASE_SERVICE_ACCOUNT.");
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(credentialInfo) });

const db = admin.firestore();
const auth = admin.auth();

async function setupCAD31() {
  const email = process.env.SCHOOL_ADMIN_EMAIL?.trim();
  const password = process.env.SCHOOL_ADMIN_PASSWORD?.trim();
  const name = process.env.SCHOOL_ADMIN_NAME?.trim() || 'Administrador';
  const unitCode = process.env.SCHOOL_UNIT_CODE?.trim().toUpperCase() || 'CAD31';
  const schoolName = process.env.SCHOOL_NAME?.trim() || unitCode;

  if (!email || !password || password.length < 8) {
    console.error('Define SCHOOL_ADMIN_EMAIL y SCHOOL_ADMIN_PASSWORD (min. 8 caracteres) en .env.local');
    process.exit(1);
  }

  console.log('------------------------------------------');
  console.log('  Configurando cuenta CAD31 - CADE');
  console.log('------------------------------------------');

  // 1. Crear o actualizar usuario en Firebase Auth
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
    console.log(`✓ Usuario encontrado: ${userRecord.uid}`);
    await auth.updateUser(userRecord.uid, {
      displayName: name,
      password: password,
    });
    console.log(`✓ Contraseña y nombre actualizados.`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      userRecord = await auth.createUser({ email, password, displayName: name });
      console.log(`✓ Usuario creado: ${userRecord.uid}`);
    } else {
      throw e;
    }
  }

  // 2. Crear / sobrescribir el documento de la empresa CAD31
  await db.collection('companies').doc(unitCode).set({
    name: schoolName,
    unitCode: unitCode,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    adminUid: userRecord.uid,
    adminEmail: email,
    status: 'active'
  }, { merge: true });
  console.log(`✓ Documento companies/${unitCode} actualizado.`);

  // 3. Asignar perfil de Admin en Firestore
  await db.collection('users').doc('admins').collection('members').doc(userRecord.uid).set({
    uid: userRecord.uid,
    name: name,
    email: email,
    role: 'admin',
    unitCode: unitCode,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  console.log(`✓ Perfil de administrador registrado en Firestore.`);

  console.log('');
  console.log('========================================');
  console.log('  ✅ CAD31 CONFIGURADO EXITOSAMENTE');
  console.log('========================================');
  console.log(`  Colegio  : ${schoolName}`);
  console.log(`  Código   : ${unitCode}`);
  console.log(`  Admin    : ${name}`);
  console.log(`  Correo   : ${email}`);
  console.log(`  Clave    : ${password}`);
  console.log('========================================');
  process.exit(0);
}

setupCAD31().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
