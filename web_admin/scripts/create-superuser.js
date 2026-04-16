require('dotenv').config({ path: '.env.local' });
const admin = require('firebase-admin');

// Parse the service account from env
let credentialInfo;
try {
  credentialInfo = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  if (credentialInfo.private_key) {
      credentialInfo.private_key = credentialInfo.private_key.replace(/\\n/g, '\n');
  }
} catch (e) {
  console.error("Error parsing FIREBASE_SERVICE_ACCOUNT. Make sure it's valid JSON.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(credentialInfo)
});

const db = admin.firestore();
const auth = admin.auth();

async function createSuperAdmin() {
  const email = 'csavilaf95@gmail.com';
  const password = 'Admin123';
  const name = 'Carlos Super Admin';

  try {
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log('User already exists, updating password...');
      await auth.updateUser(userRecord.uid, { password });
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await auth.createUser({
          email,
          password,
          displayName: name,
        });
        console.log('Successfully created new user:', userRecord.uid);
      } else {
        throw e;
      }
    }

    // Assign Super Admin Role
    await db.collection('users').doc('super_admins').collection('members').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      name: name,
      role: 'super_admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('--- SUPER ADMIN CREATED SUCCESSFULLY ---');
    console.log(`Email: ${email}`);
    process.exit(0);

  } catch (error) {
    console.error('Error creating super admin:', error);
    process.exit(1);
  }
}

createSuperAdmin();
