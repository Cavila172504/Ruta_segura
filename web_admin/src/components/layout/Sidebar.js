"use client";
import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

import { auth, db } from '@/lib/firebase';
import { signOut } from 'firebase/auth';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { useAuth } from '@/context/AuthContext';

const Sidebar = ({ profile }) => {
  const { SCHOOL_CODE } = useAuth();
  const pathname = usePathname();
  const router = useRouter();

  const [pendingCount, setPendingCount] = React.useState(0);

  React.useEffect(() => {
    if (!SCHOOL_CODE) return;

    const q = query(
      collection(db, 'companies', SCHOOL_CODE, 'students'),
      where('status', '==', 'pending')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      setPendingCount(snapshot.size);
    });

    return () => unsubscribe();
  }, [SCHOOL_CODE]);

  const handleLogout = async () => {
      try {
          await signOut(auth);
          router.push('/login');
      } catch (error) {
          console.error('Error signing out', error);
      }
  };

  const menuItems = [
    { icon: 'dashboard', label: 'Dashboard', href: '/dashboard' },
    ...(profile?.role === 'super_admin' ? [{ icon: 'corporate_fare', label: 'Gestión Empresas', href: '/dashboard/companies' }] : []),
    { icon: 'person', label: 'Conductores', href: '/dashboard/drivers' },
    { icon: 'route', label: 'Rutas', href: '/dashboard/routes' },
    { 
      icon: 'how_to_reg', 
      label: 'Inscripciones', 
      href: '/dashboard/students',
      badge: pendingCount > 0 ? pendingCount : null 
    },
    { icon: 'headset_mic', label: 'Soporte', href: '/dashboard/support' },
    { icon: 'analytics', label: 'Informes', href: '/dashboard/reports' },
  ];

  return (
    <aside className="fixed left-0 top-0 h-screen w-[240px] bg-slate-50 flex flex-col py-6 border-r border-outline-variant/10">
      <div className="px-6 mb-10">
        <h1 className="text-2xl font-bold tracking-tight text-primary font-headline italic">RutaSegura</h1>
        <div className="mt-1 flex flex-col">
            <p className="text-xs font-black text-slate-500 uppercase tracking-widest leading-none">
              {profile?.role === 'super_admin' ? 'Supervisión Global' : 'School Admin'}
            </p>
            <p className="text-lg font-bold text-primary mt-1 flex items-center gap-1">
                <span className="material-symbols-outlined text-lg">verified</span>
                {profile?.role === 'super_admin' ? `SOPORTE: ${SCHOOL_CODE}` : SCHOOL_CODE}
            </p>
        </div>
      </div>
      
      <nav className="flex-1 space-y-1 overflow-y-auto">
        {menuItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link 
              key={item.label}
              href={item.href}
              className={`flex items-center gap-4 px-6 py-4 transition-all duration-200 group ${
                isActive 
                  ? 'text-primary font-black border-r-4 border-primary bg-white shadow-sm translate-x-1' 
                  : 'text-slate-600 font-bold hover:bg-slate-200/50'
              }`}
            >
              <span className="material-symbols-outlined text-2xl">{item.icon}</span>
              <span className="font-body text-lg flex-1">{item.label}</span>
              {item.badge && (
                <span className="bg-red-500 text-white text-[10px] font-black px-1.5 py-0.5 rounded-full shadow-sm">
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="px-4 border-t border-outline-variant/10 pt-6 mt-4 flex flex-col gap-2">
        <Link 
          href="/dashboard/profile"
          className={`flex items-center gap-4 px-6 py-4 transition-colors rounded-xl ${
            pathname === '/dashboard/profile' ? 'text-primary font-black bg-primary/5' : 'text-slate-600 font-bold hover:bg-slate-200/50'
          }`}
        >
          <span className="material-symbols-outlined text-2xl">account_circle</span>
          <span className="font-body text-lg">Mi Perfil</span>
        </Link>
        <button 
          onClick={handleLogout}
          className="flex items-center gap-4 px-6 py-4 w-full text-left transition-colors rounded-xl text-error font-black hover:bg-error/10"
        >
          <span className="material-symbols-outlined text-2xl">logout</span>
          <span className="font-body text-lg">Cerrar Sesión</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
