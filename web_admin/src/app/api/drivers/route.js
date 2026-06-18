import { NextResponse } from 'next/server';
import admin from 'firebase-admin';
import { adminAuth, adminDb, isAdminInitialized } from '@/lib/firebase-admin';
import { verifyApiAuth } from '@/lib/api-auth';

/** Contraseña de la app = número de cédula (solo conductores creados desde el panel). */
function driverPassword(idNumber) {
  const key = idNumber != null ? String(idNumber).trim() : '';
  if (key.length < 6) {
    return null;
  }
  return key;
}

async function upsertDriverAuthLookup(idNumber, email, unitCode) {
  const key = idNumber != null ? String(idNumber).trim() : '';
  if (key.length < 6 || !email) return;
  await adminDb.collection('driver_auth_lookup').doc(key).set({
    email: String(email).trim().toLowerCase(),
    unitCode,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function deleteDriverAuthLookup(idNumber) {
  const key = idNumber != null ? String(idNumber).trim() : '';
  if (key.length < 6) return;
  await adminDb.collection('driver_auth_lookup').doc(key).delete();
}

function normalizeUnitCode(unitCode) {
  return unitCode != null ? String(unitCode).trim().toUpperCase() : '';
}

function mapDriverApiError(error) {
  const code = error?.code || '';
  const message = error?.message || 'Error desconocido';

  if (code === 'auth/email-already-exists') {
    return 'Ese correo ya está registrado en Firebase. Use un correo distinto para el conductor (no el mismo del administrador).';
  }
  if (code === 'auth/invalid-email') {
    return 'Correo electrónico no válido.';
  }
  if (code === 'auth/weak-password') {
    return 'La cédula debe tener al menos 6 caracteres (contraseña de la app).';
  }
  if (code === 'auth/user-not-found') {
    return 'El usuario del conductor no existe en Firebase Auth (puede haber sido eliminado manualmente).';
  }
  if (message.includes('FIREBASE_SERVICE_ACCOUNT') || message.includes('default credentials')) {
    return 'Firebase Admin no está configurado en el servidor (variable FIREBASE_SERVICE_ACCOUNT).';
  }
  return message;
}

function ensureAdminReady() {
  if (!isAdminInitialized() || !adminAuth || !adminDb) {
    return NextResponse.json(
      {
        error:
          'Servidor sin Firebase Admin. Configure FIREBASE_SERVICE_ACCOUNT en el hosting de producción.',
      },
      { status: 503 }
    );
  }
  return null;
}

export async function POST(request) {
  const notReady = ensureAdminReady();
  if (notReady) return notReady;

  const body = await request.json();
  const unitCode = normalizeUnitCode(body.unitCode);

  const authResult = await verifyApiAuth(request, {
    roles: ['admin', 'super_admin'],
    unitCode,
  });
  if (authResult.error) return authResult.error;

  let createdUid = null;
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
      email: String(email).trim().toLowerCase(),
      password,
      displayName: `${names} ${lastNames}`,
      emailVerified: true,
    });

    createdUid = userRecord.uid;
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

    await upsertDriverAuthLookup(idNumberStr, email, unitCode);

    return NextResponse.json({ success: true, uid });
  } catch (error) {
    console.error('Error creating driver:', error);
    if (createdUid) {
      try {
        await adminAuth.deleteUser(createdUid);
      } catch (rollbackErr) {
        console.error('Rollback createUser failed:', rollbackErr);
      }
    }
    return NextResponse.json({ error: mapDriverApiError(error) }, { status: 500 });
  }
}

export async function PATCH(request) {
  const notReady = ensureAdminReady();
  if (notReady) return notReady;

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
      unitCode: rawUnitCode,
    } = data;

    const unitCode = normalizeUnitCode(rawUnitCode);

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
      email: email ? String(email).trim().toLowerCase() : undefined,
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

    await upsertDriverAuthLookup(idNumberStr, email, unitCode);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error updating driver:', error);
    return NextResponse.json({ error: mapDriverApiError(error) }, { status: 500 });
  }
}

export async function DELETE(request) {
  const notReady = ensureAdminReady();
  if (notReady) return notReady;

  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const unitCode = normalizeUnitCode(searchParams.get('unitCode'));

    if (!id || !unitCode) {
      return NextResponse.json({ error: 'Faltan parámetros (id, unitCode)' }, { status: 400 });
    }

    const authResult = await verifyApiAuth(request, {
      roles: ['admin', 'super_admin'],
      unitCode,
    });
    if (authResult.error) return authResult.error;

    const driverSnap = await adminDb
      .collection('companies')
      .doc(unitCode)
      .collection('drivers')
      .doc(id)
      .get();
    const oldIdNumber = driverSnap.exists ? driverSnap.data()?.idNumber : null;

    try {
      await adminAuth.deleteUser(id);
    } catch (authErr) {
      if (authErr?.code !== 'auth/user-not-found') throw authErr;
    }

    await adminDb.collection('companies').doc(unitCode).collection('drivers').doc(id).delete();
    await adminDb.collection('users').doc('drivers').collection('members').doc(id).delete();
    await deleteDriverAuthLookup(oldIdNumber);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting driver:', error);
    return NextResponse.json({ error: mapDriverApiError(error) }, { status: 500 });
  }
}
