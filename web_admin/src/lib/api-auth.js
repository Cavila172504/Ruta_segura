import { NextResponse } from 'next/server';
import { adminAuth, adminDb, isAdminInitialized } from '@/lib/firebase-admin';

export async function resolveUserRole(uid) {
  const superSnap = await adminDb.collection('users').doc('super_admins').collection('members').doc(uid).get();
  if (superSnap.exists) return { role: 'super_admin', profile: superSnap.data() };

  const adminSnap = await adminDb.collection('users').doc('admins').collection('members').doc(uid).get();
  if (adminSnap.exists) {
    const data = adminSnap.data();
    return { role: data.role || 'admin', profile: data };
  }

  const driverSnap = await adminDb.collection('users').doc('drivers').collection('members').doc(uid).get();
  if (driverSnap.exists) return { role: 'driver', profile: driverSnap.data() };

  return { role: null, profile: null };
}

export async function verifyApiAuth(request, options = {}) {
  const { roles = ['admin', 'super_admin'], unitCode = null, allowViewer = false } = options;

  if (!isAdminInitialized()) {
    return { error: NextResponse.json({
      error: 'Servidor sin Firebase Admin. Configure FIREBASE_SERVICE_ACCOUNT en el hosting de producción.',
    }, { status: 503 }), user: null };
  }

  const authHeader = request.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return { error: NextResponse.json({ error: 'No autorizado' }, { status: 401 }), user: null };
  }

  try {
    const decoded = await adminAuth.verifyIdToken(authHeader.slice(7));
    const { role, profile } = await resolveUserRole(decoded.uid);

    if (!role) return { error: NextResponse.json({ error: 'Sin permisos' }, { status: 403 }), user: null };

    const allowed = [...roles];
    if (allowViewer && role === 'viewer') allowed.push('viewer');
    if (!allowed.includes(role)) {
      return { error: NextResponse.json({ error: 'Sin permisos' }, { status: 403 }), user: null };
    }

    if (unitCode && role !== 'super_admin') {
      const profileUnit = profile?.unitCode != null ? String(profile.unitCode).trim().toUpperCase() : '';
      const requestedUnit = String(unitCode).trim().toUpperCase();
      if (profileUnit !== requestedUnit) {
        return { error: NextResponse.json({ error: 'Sin acceso a unidad' }, { status: 403 }), user: null };
      }
    }

    return { error: null, user: { uid: decoded.uid, role, profile, email: decoded.email } };
  } catch (e) {
    return { error: NextResponse.json({ error: 'Token invalido' }, { status: 401 }), user: null };
  }
}

export function requireSuperAdmin(user) {
  if (user?.role !== 'super_admin') {
    return NextResponse.json({ error: 'Requiere super admin' }, { status: 403 });
  }
  return null;
}