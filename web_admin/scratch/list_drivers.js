const admin = require('firebase-admin');
const fs = require('fs');

const serviceAccountPath = 'c:/Proyecto/Rutasegura/web_admin/scripts/serviceAccountKey.json';
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

async function listDrivers() {
    console.log("=== LISTANDO CONDUCTORES ===");
    const snapshot = await db.collectionGroup('drivers').get();
    console.log(`Total documentos encontrados en subcolecciones 'drivers': ${snapshot.size}`);
    
    snapshot.forEach(doc => {
        console.log(`Path: ${doc.ref.path} -> Name: ${doc.data().name} (${doc.data().email})`);
    });
    
    console.log("=== LISTANDO PERFILES GLOBALES ===");
    const globalSnapshot = await db.collection('users').doc('drivers').collection('members').get();
    console.log(`Total perfiles globales: ${globalSnapshot.size}`);
    globalSnapshot.forEach(doc => {
        console.log(`UID: ${doc.id} -> Name: ${doc.data().name} (${doc.data().email})`);
    });
    
    process.exit(0);
}

listDrivers().catch(console.error);
