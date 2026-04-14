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

async function syncAllDrivers() {
    console.log("Iniciando sincronización global de conductores...");
    
    // Obtener todas las compañías (CAD31, etc)
    const companiesSnapshot = await db.collection('companies').get();
    
    for (const companyDoc of companiesSnapshot.docs) {
        const unitCode = companyDoc.id;
        console.log(`Procesando institución: ${unitCode}`);
        
        const driversSnapshot = await db.collection('companies').doc(unitCode).collection('drivers').get();
        
        for (const driverDoc of driversSnapshot.docs) {
            const data = driverDoc.data();
            const uid = driverDoc.id;
            
            console.log(`  Sincronizando: ${data.name || 'Sin nombre'} (${data.email})`);
            
            // Actualizar en users/drivers/members
            await db.collection('users').doc('drivers').collection('members').doc(uid).set({
                uid: uid,
                email: data.email,
                name: data.name || `${data.names} ${data.lastNames}`,
                unitCode: unitCode,
                role: 'driver'
            }, { merge: true });
        }
    }
    
    console.log("¡Sincronización completada!");
    process.exit(0);
}

syncAllDrivers().catch(console.error);
