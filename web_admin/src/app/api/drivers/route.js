import { NextResponse } from 'next/server';
import admin from 'firebase-admin';

// Initialize Admin SDK once
if (!admin.apps.length) {
    try {
        let serviceAccount;
        const serviceAccountStr = process.env.FIREBASE_SERVICE_ACCOUNT;
        
        if (serviceAccountStr) {
            serviceAccount = JSON.parse(serviceAccountStr);
        } else {
            // Cargar desde archivo local
            const fs = require('fs');
            const path = 'c:/Proyecto/Rutasegura/web_admin/scripts/serviceAccountKey.json';
            serviceAccount = JSON.parse(fs.readFileSync(path, 'utf8'));
        }

        if (serviceAccount) {
            // Asegurar que las nuevas líneas en la clave privada sean correctas
            if (serviceAccount.private_key) {
                serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
            }
            
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log("Firebase Admin SDK inicializado correctamente.");
        }
    } catch (error) {
        console.error("Error crítico de inicialización de Firebase Admin:", error.message);
    }
}

export async function POST(request) {
  try {
    const data = await request.json();
    const { 
        names, lastNames, email, idNumber, accessKey = null, 
        phoneRes = null, phoneCell, address, cooperative, docType, 
        unitCode 
    } = data;

    if (!admin.apps.length) {
        throw new Error("El SDK de administración de Firebase no está configurado.");
    }

    // 1. Crear usuario en Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: accessKey || idNumber, 
      displayName: `${names} ${lastNames}`,
      emailVerified: true, // Evita la validación de correo en la App
    });

    const uid = userRecord.uid;

    // 2. Crear perfil en Firestore
    const db = admin.firestore();
    await db.collection('companies').doc(unitCode).collection('drivers').doc(uid).set({
      uid: uid,
      names,
      lastNames,
      name: `${names} ${lastNames}`,
      email: email,
      idNumber: idNumber,
      docType: docType,
      phoneRes: phoneRes,
      phoneCell: phoneCell,
      address: address,
      cooperative: cooperative,
      role: 'driver',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active'
    });

    // 3. Vincular a nivel global de usuarios
    await db.collection('users').doc('drivers').collection('members').doc(uid).set({
        uid: uid,
        email: email,
        name: `${names} ${lastNames}`,
        unitCode: unitCode,
        role: 'driver'
    });

    return NextResponse.json({ success: true, uid: uid });
  } catch (error) {
    console.error("Error creating driver:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// ACTUALIZACIÓN UNIFICADA (PATCH)
export async function PATCH(request) {
    try {
      const { searchParams } = new URL(request.url);
      const id = searchParams.get('id');
      const data = await request.json();
      const { names, lastNames, email, accessKey = null, phoneRes = null, phoneCell, address, cooperative, docType, unitCode } = data;
  
      if (!id || !unitCode) throw new Error("Faltan parámetros (id, unitCode)");
      if (!admin.apps.length) throw new Error("SDK no configurado");
  
      const updateData = {
        names,
        lastNames,
        name: `${names} ${lastNames}`,
        phoneRes,
        phoneCell,
        address,
        cooperative,
        docType,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
  
      // Forzar verificación de correo para evitar bloqueos en la App
      await admin.auth().updateUser(id, {
        emailVerified: true,
        ...(accessKey && { password: accessKey })
      });
  
      const db = admin.firestore();
      await db.collection('companies').doc(unitCode).collection('drivers').doc(id).update(updateData);
      
      // Sincronizar también a nivel global (usar set+merge para evitar error si no existe el doc)
      await db.collection('users').doc('drivers').collection('members').doc(id).set({
        name: updateData.name,
        email: email,
        unitCode: unitCode,
        role: 'driver'
      }, { merge: true });
  
      return NextResponse.json({ success: true });
    } catch (error) {
      console.error("Error updating driver:", error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
}

export async function DELETE(request) {
  console.log("Iniciando proceso de eliminación...");
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const unitCode = searchParams.get('unitCode');

    console.log("Parámetros recibidos:", { id, unitCode });

    if (!id || !unitCode) {
        console.error("Error: Faltan parámetros en DELETE");
        return NextResponse.json({ error: "Faltan parámetros (id, unitCode)" }, { status: 400 });
    }

    // 1. Eliminar de Firebase Auth
    await admin.auth().deleteUser(id);

    // 2. Eliminar de Firestore (Compañía)
    const db = admin.firestore();
    await db.collection('companies').doc(unitCode).collection('drivers').doc(id).delete();

    // 3. Eliminar de Firestore (Global)
    await db.collection('users').doc('drivers').collection('members').doc(id).delete();

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting driver:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
