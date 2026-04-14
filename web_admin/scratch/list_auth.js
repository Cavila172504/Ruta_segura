const admin = require('firebase-admin');
const fs = require('fs');

const serviceAccountPath = 'c:/Proyecto/Rutasegura/web_admin/scripts/serviceAccountKey.json';
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

async function listAuthUsers() {
    console.log("=== LISTANDO USUARIOS EN AUTH ===");
    const listUsersResult = await admin.auth().listUsers(100);
    listUsersResult.users.forEach((userRecord) => {
        console.log(`UID: ${userRecord.uid} | Email: ${userRecord.email} | Name: ${userRecord.displayName}`);
    });
    process.exit(0);
}

listAuthUsers().catch(console.error);
