import { NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { verifyApiAuth, requireSuperAdmin } from '@/lib/api-auth';

export async function GET(request) {
  const authResult = await verifyApiAuth(request, { roles: ['super_admin'] });
  if (authResult.error) return authResult.error;
  const forbidden = requireSuperAdmin(authResult.user);
  if (forbidden) return forbidden;

  try {
    const companiesSnap = await adminDb.collection('companies').get();
    const stats = [];

    for (const doc of companiesSnap.docs) {
      const data = doc.data();
      const unitCode = doc.id;

      const [driversSnap, studentsSnap, adminsSnap] = await Promise.all([
        adminDb.collection('companies').doc(unitCode).collection('drivers').get(),
        adminDb.collection('companies').doc(unitCode).collection('students').get(),
        adminDb.collection('users').doc('admins').collection('members').where('unitCode', '==', unitCode).limit(1).get(),
      ]);

      const students = studentsSnap.docs.map((d) => d.data());
      const activeStudents = students.filter((s) => s.status === 'active').length;
      const pendingStudents = students.filter((s) => s.status === 'pending').length;

      const adminDoc = adminsSnap.docs[0]?.data();

      stats.push({
        unitCode,
        name: data.name || unitCode,
        adminEmail: data.adminEmail || adminDoc?.email || null,
        adminName: adminDoc?.name || null,
        adminUid: data.adminUid || adminDoc?.uid || null,
        status: data.status || 'active',
        transportCompany: data.transportCompany || '',
        schoolLat: data.schoolLat ?? null,
        schoolLng: data.schoolLng ?? null,
        schoolAddress: data.schoolAddress || '',
        hasSchoolLocation: data.schoolLat != null && data.schoolLng != null,
        driversCount: driversSnap.size,
        studentsTotal: studentsSnap.size,
        studentsActive: activeStudents,
        studentsPending: pendingStudents,
        createdAt: data.createdAt || null,
      });
    }

    stats.sort((a, b) => a.name.localeCompare(b.name));

    const totals = stats.reduce(
      (acc, s) => ({
        companies: acc.companies + 1,
        drivers: acc.drivers + s.driversCount,
        students: acc.students + s.studentsTotal,
        studentsActive: acc.studentsActive + s.studentsActive,
      }),
      { companies: 0, drivers: 0, students: 0, studentsActive: 0 }
    );

    return NextResponse.json({ totals, companies: stats });
  } catch (error) {
    console.error('Error fetching company stats:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
