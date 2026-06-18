import { NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase-admin';
import { verifyApiAuth, requireSuperAdmin } from '@/lib/api-auth';
import admin from 'firebase-admin';
import { normalizeUnitCode } from '@/lib/admin-api';

async function deleteSchoolUser({ uid, unitCode }) {
  if (!uid || !unitCode) {
    return NextResponse.json({ error: 'Faltan campos obligatorios' }, { status: 400 });
  }

  const normalizedCode = normalizeUnitCode(unitCode);
  const memberRef = adminDb.collection('users').doc('admins').collection('members').doc(uid);
  const memberSnap = await memberRef.get();

  if (!memberSnap.exists) {
    return NextResponse.json({ error: 'Usuario no encontrado' }, { status: 404 });
  }

  const member = memberSnap.data();
  if (normalizeUnitCode(member.unitCode) !== normalizedCode) {
    return NextResponse.json({ error: 'El usuario no pertenece a este colegio' }, { status: 403 });
  }

  await memberRef.delete();
  await adminAuth.deleteUser(uid);

  return NextResponse.json({ success: true });
}

export async function POST(request) {
  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;

  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  try {
    const body = await request.json();

    if (body.action === 'delete') {
      return deleteSchoolUser(body);
    }

    const { email, password, name, unitCode, role } = body;

    if (!email || !password || !name || !unitCode || !role) {
      return NextResponse.json({ error: 'Faltan campos obligatorios' }, { status: 400 });
    }

    if (password.length < 8) {
      return NextResponse.json(
        { error: 'La contraseña debe tener al menos 8 caracteres' },
        { status: 400 }
      );
    }

    if (!['admin', 'viewer'].includes(role)) {
      return NextResponse.json({ error: 'Rol invalido. Usa admin o viewer' }, { status: 400 });
    }

    const normalizedCode = String(unitCode).trim().toUpperCase();
    const companySnap = await adminDb.collection('companies').doc(normalizedCode).get();
    if (!companySnap.exists) {
      return NextResponse.json({ error: `No existe el colegio con codigo ${normalizedCode}` }, { status: 400 });
    }

    const userRecord = await adminAuth.createUser({
      email,
      password,
      displayName: name,
    });

    await adminDb
      .collection('users')
      .doc('admins')
      .collection('members')
      .doc(userRecord.uid)
      .set({
        uid: userRecord.uid,
        email,
        name,
        unitCode: normalizedCode,
        role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return NextResponse.json({ success: true, uid: userRecord.uid });
  } catch (error) {
    console.error('Error creating user:', error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
