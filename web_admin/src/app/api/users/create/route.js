import { NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase-admin';
import { verifyApiAuth, requireSuperAdmin } from '@/lib/api-auth';
import admin from 'firebase-admin';

export async function POST(request) {
  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;

  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  try {
    const { email, password, name, unitCode, role } = await request.json();

    if (!email || !password || !name || !unitCode || !role) {
      return NextResponse.json({ error: 'Faltan campos obligatorios' }, { status: 400 });
    }

    if (password.length < 8) {
      return NextResponse.json(
        { error: 'La contraseña debe tener al menos 8 caracteres' },
        { status: 400 }
      );
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
        unitCode,
        role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return NextResponse.json({ success: true, uid: userRecord.uid });
  } catch (error) {
    console.error('Error creating user:', error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
