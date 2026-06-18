import { NextResponse } from 'next/server';
import { isAdminInitialized } from '@/lib/firebase-admin';

export async function GET() {
  const adminReady = isAdminInitialized();
  return NextResponse.json({
    ok: true,
    adminReady,
    mode: adminReady ? 'server-admin' : 'client-fallback-required',
    hint: adminReady
      ? 'Firebase Admin activo. Crear colegios y conductores via API.'
      : 'Configure FIREBASE_SERVICE_ACCOUNT (produccion) o FIREBASE_SERVICE_ACCOUNT_PATH (local).',
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'rutasegura-a74f7',
  });
}