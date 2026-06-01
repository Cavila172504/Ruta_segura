import { NextResponse } from 'next/server';
import admin from 'firebase-admin';
import { adminAuth, adminDb } from '@/lib/firebase-admin';
import { verifyApiAuth } from '@/lib/api-auth';

/** Contraseña de la app = número de cédula (solo conductores creados desde el panel). */
function driverPassword(idNumber) {
  const key = idNumber != null ? String(idNumber).trim() : '';
  if (key.length < 6) {
    return null;
  }
  return key;
}

export async function POST(request) {
  const body = await request.json();
  const { unitCode } = body;

  const authResult = await verifyApiAuth(request, {
    roles: ['admin', 'super_admin'],
    unitCode,
  });
  if (authResult.error) return authResult.error;

  try {
    const {
      names,
      lastNames,
      email,
      idNumber,
      phoneRes = null,
      phoneCell,
      address,
      cooperative,
      docType,
    } = body;

    const password = driverPassword(idNumber);
    if (!password) {
      return NextResponse.json(
        { error: 'La cédula debe tener al menos 6 caracteres (contraseña de acceso en la app).' },
        { status: 400 }
      );
    }

    if (!email || !names || !lastNames) {
      return NextResponse.json({ error: 'Faltan datos obligatorios del conductor' }, { status: 400 });
    }

    const userRecord = await adminAuth.createUser({
      email,
      password,
      displayName: `${names} ${lastNames}`,
      emailVerified: true,
    });

    const uid = userRecord.uid;
    const idNumberStr = String(idNumber).trim();

    await adminDb.collection('companies').doc(unitCode).collection('drivers').doc(uid).set({
      uid,
      names,
      lastNames,
      name: `${names} ${lastNames}`,
      email,
      idNumber: idNumberStr,
      docType,
      phoneRes,
      phoneCell,
      address,
      cooperative,
      role: 'driver',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active',
    });

    await adminDb.collection('users').doc('drivers').collection('members').doc(uid).set({
      uid,
      email,
      name: `${names} ${lastNames}`,
      unitCode,
      idNumber: idNumberStr,
      role: 'driver',
    });

    return NextResponse.json({ success: true, uid });
  } catch (error) {
    console.error('Error creating driver:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function PATCH(request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const data = await request.json();
    const {
      names,
      lastNames,
      email,
      idNumber,
      phoneRes = null,
      phoneCell,
      address,
      cooperative,
      docType,
      unitCode,
    } = data;

    if (!id || !unitCode) {
      return NextResponse.json({ error: 'Faltan parámetros (id, unitCode)' }, { status: 400 });
    }

    const authResult = await verifyApiAuth(request, {
      roles: ['admin', 'super_admin'],
      unitCode,
    });
    if (authResult.error) return authResult.error;

    const idNumberStr = idNumber != null ? String(idNumber).trim() : '';
    const password = driverPassword(idNumberStr);
    if (!password) {
      return NextResponse.json(
        { error: 'La cédula debe tener al menos 6 caracteres.' },
        { status: 400 }
      );
    }

    const updateData = {
      names,
      lastNames,
      name: `${names} ${lastNames}`,
      idNumber: idNumberStr,
      phoneRes,
      phoneCell,
      address,
      cooperative,
      docType,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await adminAuth.updateUser(id, {
      emailVerified: true,
      password,
    });

    await adminDb
      .collection('companies')
      .doc(unitCode)
      .collection('drivers')
      .doc(id)
      .update(updateData);

    await adminDb
      .collection('users')
      .doc('drivers')
      .collection('members')
      .doc(id)
      .set(
        {
          name: updateData.name,
          email,
          unitCode,
          idNumber: idNumberStr,
          role: 'driver',
        },
        { merge: true }
      );

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating driver:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const unitCode = searchParams.get('unitCode');

    if (!id || !unitCode) {
      return NextResponse.json({ error: 'Faltan parámetros (id, unitCode)' }, { status: 400 });
    }

    const authResult = await verifyApiAuth(request, {
      roles: ['admin', 'super_admin'],
      unitCode,
    });
    if (authResult.error) return authResult.error;

    await adminAuth.deleteUser(id);
    await adminDb.collection('companies').doc(unitCode).collection('drivers').doc(id).delete();
    await adminDb.collection('users').doc('drivers').collection('members').doc(id).delete();

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting driver:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
