import { collection, getDocs, query, where, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export async function fetchCompaniesStatsFromClient() {
  const companiesSnap = await getDocs(collection(db, 'companies'));
  const stats = [];

  for (const docSnap of companiesSnap.docs) {
    const data = docSnap.data();
    const unitCode = docSnap.id.toUpperCase();

    const [driversSnap, studentsSnap] = await Promise.all([
      getDocs(collection(db, 'companies', unitCode, 'drivers')),
      getDocs(collection(db, 'companies', unitCode, 'students')),
    ]);

    let adminDoc = null;
    if (data.adminUid) {
      const adminsSnap = await getDocs(
        query(
          collection(db, 'users', 'admins', 'members'),
          where('uid', '==', data.adminUid),
          limit(1)
        )
      );
      adminDoc = adminsSnap.docs[0]?.data() || null;
    }
    if (!adminDoc) {
      const adminsSnap = await getDocs(
        query(
          collection(db, 'users', 'admins', 'members'),
          where('unitCode', '==', unitCode),
          limit(1)
        )
      );
      adminDoc = adminsSnap.docs[0]?.data() || null;
    }

    const students = studentsSnap.docs.map((d) => d.data());
    const activeStudents = students.filter((s) => s.status === 'active').length;
    const pendingStudents = students.filter((s) => s.status === 'pending').length;
    const billing = data.billing || {
      plan: 'basic',
      monthlyUsd: 0,
      status: 'active',
      studentLimit: 80,
      driverLimit: 2,
    };

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
      billing,
      billingPlan: billing.plan || 'basic',
      billingStatus: billing.status || 'active',
      monthlyUsd: billing.monthlyUsd ?? 0,
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

  return { totals, companies: stats };
}