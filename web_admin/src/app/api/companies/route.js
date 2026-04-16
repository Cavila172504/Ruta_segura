import { NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase-admin';

export async function POST(request) {
  try {
    const { unitCode, companyName, adminName, adminEmail, adminPassword } = await request.json();

    if (!unitCode || !companyName || !adminEmail || !adminPassword) {
      return NextResponse.json({ error: 'Faltan campos requeridos' }, { status: 400 });
    }

    // 1. Comprobar si el colegio / empresa ya existe
    const companyRef = adminDb.collection('companies').doc(unitCode);
    const companyDoc = await companyRef.get();
    if (companyDoc.exists) {
      return NextResponse.json({ error: 'El código de colegio ya existe. Usa uno diferente.' }, { status: 400 });
    }

    // 2. Crear al usuario (Administrador) en Firebase Auth con su contraseña
    const userRecord = await adminAuth.createUser({
      email: adminEmail,
      password: adminPassword,
      displayName: adminName,
    });

    // 3. Crear el registro base de la empresa en Firestore
    await companyRef.set({
      name: companyName,
      unitCode: unitCode,
      createdAt: new Date(),
      adminUid: userRecord.uid,
      adminEmail: adminEmail,
      status: 'active'
    });

    // 4. Asignar el rol de "Admin" y guardarlo en la base de datos con su unitCode
    await adminDb.collection('users').doc('admins').collection('members').doc(userRecord.uid).set({
      uid: userRecord.uid,
      name: adminName,
      email: adminEmail,
      role: 'admin',
      unitCode: unitCode,
      createdAt: new Date()
    });

    return NextResponse.json({ message: 'Empresa creada exitosamente', unitCode });
  } catch (error) {
    console.error('Error creating company:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function GET() {
  try {
    const snapshot = await adminDb.collection('companies').get();
    const companies = [];
    snapshot.forEach(doc => {
      let data = doc.data();
      // Solo devolver campos seguros
      companies.push({ 
        id: doc.id, 
        name: data.name, 
        unitCode: data.unitCode, 
        adminEmail: data.adminEmail,
        createdAt: data.createdAt
      });
    });
    return NextResponse.json({ companies });
  } catch (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request) {
  try {
    const { searchParams } = new URL(request.url);
    const unitCode = searchParams.get('unitCode');

    if (!unitCode) {
      return NextResponse.json({ error: 'Se requiere el unitCode para eliminar.' }, { status: 400 });
    }

    // 1. Obtener la compañía para encontrar al adminUid
    const companyRef = adminDb.collection('companies').doc(unitCode);
    const companyDoc = await companyRef.get();
    
    if (!companyDoc.exists) {
      return NextResponse.json({ error: 'La compañía no existe.' }, { status: 404 });
    }

    const { adminUid } = companyDoc.data();

    // 2. Eliminar el documento principal de la empresa
    await companyRef.delete();

    if (adminUid) {
      // 3. Eliminar al administrador de Firestore
      await adminDb.collection('users').doc('admins').collection('members').doc(adminUid).delete();
      
      // 4. Eliminar la cuenta del administrador en Firebase Auth
      try {
        await adminAuth.deleteUser(adminUid);
      } catch (authError) {
        console.error('Error al eliminar usuario en Auth (puede que ya no exista):', authError);
      }
    }

    return NextResponse.json({ message: 'Colegio y credenciales eliminados exitosamente.' });
  } catch (error) {
    console.error('Error deleting company:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function PATCH(request) {
  try {
    const { unitCode, companyName, adminName, newPassword } = await request.json();

    if (!unitCode) {
      return NextResponse.json({ error: 'Falta el código de la unidad a modificar.' }, { status: 400 });
    }

    const companyRef = adminDb.collection('companies').doc(unitCode);
    const companyDoc = await companyRef.get();
    
    if (!companyDoc.exists) {
      return NextResponse.json({ error: 'La compañía no existe.' }, { status: 404 });
    }
    
    const { adminUid } = companyDoc.data();

    let updates = {};
    if (companyName) updates.name = companyName;
    
    if (Object.keys(updates).length > 0) {
        await companyRef.update(updates);
    }

    if (adminUid) {
        let adminUpdates = {};
        if (adminName) adminUpdates.name = adminName;
        
        if (Object.keys(adminUpdates).length > 0) {
             await adminDb.collection('users').doc('admins').collection('members').doc(adminUid).update(adminUpdates);
             await adminAuth.updateUser(adminUid, { displayName: adminName });
        }

        // Si el Super Admin proporcionó una nueva contraseña, actualizamos la cuenta en Firebase Auth.
        if (newPassword && newPassword.trim().length > 0) {
            await adminAuth.updateUser(adminUid, { password: newPassword });
        }
    }

    return NextResponse.json({ message: 'Datos y credenciales actualizados exitosamente.' });
  } catch (error) {
    console.error('Error updating company:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
