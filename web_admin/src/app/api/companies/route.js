import { NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase-admin';
import { verifyApiAuth, requireSuperAdmin } from '@/lib/api-auth';
import {
  ensureAdminReady,
  mapAuthApiError,
  normalizeUnitCode,
  rollbackAuthUser,
} from '@/lib/admin-api';

function parseCoord(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

export async function POST(request) {
  const notReady = ensureAdminReady();
  if (notReady) return notReady;

  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;
  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  let createdUid = null;

  try {
    const body = await request.json();
    const unitCode = normalizeUnitCode(body.unitCode);
    const { companyName, adminName, adminEmail, adminPassword, transportCompany, schoolAddress } = body;
    const schoolLat = parseCoord(body.schoolLat);
    const schoolLng = parseCoord(body.schoolLng);

    if (!unitCode || !companyName || !adminEmail || !adminPassword) {
      return NextResponse.json({ error: 'Faltan campos requeridos' }, { status: 400 });
    }

    if (schoolLat == null || schoolLng == null) {
      return NextResponse.json(
        { error: 'Debes indicar la ubicación del colegio en el mapa (latitud y longitud).' },
        { status: 400 }
      );
    }

    if (adminPassword.length < 8) {
      return NextResponse.json(
        { error: 'La contraseña del administrador debe tener al menos 8 caracteres' },
        { status: 400 }
      );
    }

    const companyRef = adminDb.collection('companies').doc(unitCode);
    const companyDoc = await companyRef.get();
    if (companyDoc.exists) {
      return NextResponse.json(
        { error: 'El código de colegio ya existe. Usa uno diferente.' },
        { status: 400 }
      );
    }

    const userRecord = await adminAuth.createUser({
      email: adminEmail,
      password: adminPassword,
      displayName: adminName,
    });
    createdUid = userRecord.uid;

    await companyRef.set({
      name: companyName.trim(),
      unitCode,
      transportCompany: transportCompany?.trim() || '',
      schoolLat,
      schoolLng,
      schoolAddress: schoolAddress?.trim() || '',
      createdAt: new Date(),
      adminUid: userRecord.uid,
      adminEmail,
      status: 'active',
      billing: {
        plan: 'basic',
        monthlyUsd: 0,
        status: 'active',
        studentLimit: 80,
        driverLimit: 2,
      },
    });

    await adminDb
      .collection('users')
      .doc('admins')
      .collection('members')
      .doc(userRecord.uid)
      .set({
        uid: userRecord.uid,
        name: adminName,
        email: adminEmail,
        role: 'admin',
        unitCode,
        createdAt: new Date(),
      });

    return NextResponse.json({ message: 'Empresa creada exitosamente', unitCode });
  } catch (error) {
    console.error('Error creating company:', error);
    if (createdUid) await rollbackAuthUser(createdUid);
    return NextResponse.json({ error: mapAuthApiError(error) }, { status: 500 });
  }
}

export async function GET(request) {
  const notReady = ensureAdminReady();
  if (notReady) return notReady;

  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;
  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  try {
    const snapshot = await adminDb.collection('companies').get();
    const companies = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      companies.push({
        id: doc.id,
        name: data.name,
        unitCode: data.unitCode,
        adminEmail: data.adminEmail,
        createdAt: data.createdAt,
      });
    });
    return NextResponse.json({ companies });
  } catch (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request) {
  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;
  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  try {
    const { searchParams } = new URL(request.url);
    const unitCode = normalizeUnitCode(searchParams.get('unitCode'));

    if (!unitCode) {
      return NextResponse.json({ error: 'Se requiere el unitCode para eliminar.' }, { status: 400 });
    }

    const companyRef = adminDb.collection('companies').doc(unitCode);
    const companyDoc = await companyRef.get();

    if (!companyDoc.exists) {
      return NextResponse.json({ error: 'La compañía no existe.' }, { status: 404 });
    }

    const { adminUid } = companyDoc.data();
    await companyRef.delete();

    if (adminUid) {
      await adminDb.collection('users').doc('admins').collection('members').doc(adminUid).delete();
      try {
        await adminAuth.deleteUser(adminUid);
      } catch (authError) {
        console.error('Error al eliminar usuario en Auth:', authError);
      }
    }

    return NextResponse.json({ message: 'Colegio y credenciales eliminados exitosamente.' });
  } catch (error) {
    console.error('Error deleting company:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function PATCH(request) {
  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;
  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  try {
    const body = await request.json();
    const unitCode = normalizeUnitCode(body.unitCode);
    const { companyName, adminName, newPassword, transportCompany, schoolAddress } = body;
    const schoolLat = body.schoolLat !== undefined ? parseCoord(body.schoolLat) : undefined;
    const schoolLng = body.schoolLng !== undefined ? parseCoord(body.schoolLng) : undefined;

    if (!unitCode) {
      return NextResponse.json({ error: 'Falta el código de la unidad a modificar.' }, { status: 400 });
    }

    const companyRef = adminDb.collection('companies').doc(unitCode);
    const companyDoc = await companyRef.get();

    if (!companyDoc.exists) {
      return NextResponse.json({ error: 'La compañía no existe.' }, { status: 404 });
    }

    const { adminUid } = companyDoc.data();
    const updates = {};
    if (companyName) updates.name = companyName.trim();
    if (transportCompany !== undefined) updates.transportCompany = transportCompany.trim();
    if (schoolAddress !== undefined) updates.schoolAddress = schoolAddress.trim();
    if (schoolLat != null) updates.schoolLat = schoolLat;
    if (schoolLng != null) updates.schoolLng = schoolLng;
    if (body.billing && typeof body.billing === 'object') {
      updates.billing = { ...(companyDoc.data().billing || {}), ...body.billing };
    }

    if (Object.keys(updates).length > 0) {
      await companyRef.update(updates);
    }

    if (adminUid) {
      const adminUpdates = {};
      if (adminName) adminUpdates.name = adminName;

      if (Object.keys(adminUpdates).length > 0) {
        await adminDb
          .collection('users')
          .doc('admins')
          .collection('members')
          .doc(adminUid)
          .update(adminUpdates);
        await adminAuth.updateUser(adminUid, { displayName: adminName });
      }

      if (newPassword && newPassword.trim().length >= 8) {
        await adminAuth.updateUser(adminUid, { password: newPassword.trim() });
      } else if (newPassword && newPassword.trim().length > 0) {
        return NextResponse.json(
          { error: 'La nueva contraseña debe tener al menos 8 caracteres' },
          { status: 400 }
        );
      }
    }

    return NextResponse.json({ message: 'Datos y credenciales actualizados exitosamente.' });
  } catch (error) {
    console.error('Error updating company:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
