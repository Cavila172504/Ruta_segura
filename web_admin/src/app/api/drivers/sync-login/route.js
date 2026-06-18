import { NextResponse } from 'next/server';
import admin from 'firebase-admin';
import { adminDb } from '@/lib/firebase-admin';
import { verifyApiAuth } from '@/lib/api-auth';
import { ensureAdminReady } from '@/lib/admin-api';

async function upsertDriverAuthLookup(idNumber, email, unitCode) {
  const key = idNumber != null ? String(idNumber).trim() : '';
  if (key.length < 6 || !email) return false;
  await adminDb.collection('driver_auth_lookup').doc(key).set({
    email: String(email).trim().toLowerCase(),
    unitCode,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return true;
}

/** Sincroniza driver_auth_lookup para conductores ya registrados (login app por cédula). */
export async function POST(request) {
  const notReady = ensureAdminReady();
  if (notReady) return notReady;

  const body = await request.json().catch(() => ({}));
  const { unitCode } = body;

  const authResult = await verifyApiAuth(request, {
    roles: ['admin', 'super_admin'],
    unitCode,
  });
  if (authResult.error) return authResult.error;

  if (!unitCode) {
    return NextResponse.json({ error: 'Falta unitCode' }, { status: 400 });
  }

  try {
    const snap = await adminDb
      .collection('companies')
      .doc(unitCode)
      .collection('drivers')
      .get();

    let synced = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const ok = await upsertDriverAuthLookup(data.idNumber, data.email, unitCode);
      if (ok) synced += 1;
    }

    return NextResponse.json({ success: true, synced, total: snap.size });
  } catch (error) {
    console.error('sync-login error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
