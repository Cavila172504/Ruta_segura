import { NextResponse } from 'next/server';
import { adminAuth, adminDb, isAdminInitialized } from '@/lib/firebase-admin';

export function normalizeUnitCode(code) {
  return String(code || '').trim().toUpperCase();
}

export function ensureAdminReady() {
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

export function mapAuthApiError(error) {
  const code = error?.code || '';
  const message = error?.message || 'Error desconocido';

  if (code === 'auth/email-already-exists') {
    return 'Ese correo ya está registrado. Use un correo distinto (no el del administrador).';
  }
  if (code === 'auth/invalid-email') {
    return 'Correo electrónico no válido.';
  }
  if (code === 'auth/weak-password') {
    return 'La contraseña debe tener al menos 6 caracteres.';
  }
  if (message.includes('FIREBASE_SERVICE_ACCOUNT') || message.includes('default credentials')) {
    return 'Firebase Admin no está configurado (variable FIREBASE_SERVICE_ACCOUNT).';
  }
  return message;
}

export async function rollbackAuthUser(uid) {
  if (!uid || !adminAuth) return;
  try {
    await adminAuth.deleteUser(uid);
  } catch (err) {
    console.error('Rollback deleteUser failed:', err);
  }
}
