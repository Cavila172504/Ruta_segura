const admin = require('firebase-admin');
const fs = require('fs');

let rawData = fs.readFileSync('c:/Proyecto/Rutasegura/web_admin/scripts/serviceAccountKey.json', 'utf8');
const serviceAccount = JSON.parse(rawData);
if (serviceAccount.private_key) {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
}

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

async function checkUser(email) {
    try {
        const user = await admin.auth().getUserByEmail(email);
        console.log(`User ${email}:`);
        console.log(`- UID: ${user.uid}`);
        console.log(`- Email Verified: ${user.emailVerified}`);
        
        if (!user.emailVerified) {
            await admin.auth().updateUser(user.uid, { emailVerified: true });
            console.log(`- UPDATED: User is now VERIFIED.`);
        }
    } catch (error) {
        console.error(`Error checking user ${email}:`, error.message);
    }
}

checkUser('chofer@rutasegura.com');
