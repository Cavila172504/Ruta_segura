"use client";
import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

import { auth, db } from '@/lib/firebase';
import { signOut } from 'firebase/auth';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { useAuth } from '@/context/AuthContext';

const Sidebar = ({ profile, isOpen, setIsOpen }) => {
  const { SCHOOL_CODE, setActiveUnitCode } = useAuth();
  const pathname = usePathname();
  const router = useRouter();

  const [pendingCount, setPendingCount] = React.useState(0);
  const [localUnitCode, setLocalUnitCode] = React.useState('');
  const [isEditingCode, setIsEditingCode] = React.useState(false);

  React.useEffect(() => {
    if (SCHOOL_CODE) {
      setLocalUnitCode(SCHOOL_CODE);
    }
  }, [SCHOOL_CODE]);

  const handleSaveCode = () => {
    if (localUnitCode.trim()) {
       setActiveUnitCode(localUnitCode.trim().toUpperCase());
       setIsEditingCode(false);
    }
  };


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
          if (typeof window !== 'undefined') {
              localStorage.removeItem('adminBypass');
          }
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
    <aside className={`fixed left-0 top-0 h-screen w-[240px] bg-slate-50 flex flex-col py-6 border-r border-outline-variant/10 z-50 transform transition-transform duration-300 ease-in-out md:translate-x-0 ${isOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full'}`}>
      <button 
        onClick={() => setIsOpen(false)} 
        className="md:hidden absolute top-4 right-4 text-slate-400 hover:text-slate-600 transition-colors"
      >
        <span className="material-symbols-outlined text-xl">close</span>
      </button>
      <div className="px-6 mb-10 mt-2 md:mt-0">
        <h1 className="text-2xl font-bold tracking-tight text-primary font-headline italic">RutaSegura</h1>
        <div className="mt-1 flex flex-col">
            <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest leading-none">
              {profile?.role === 'super_admin' ? 'Supervisión Global' : 'School Admin'}
            </p>
            {profile?.role === 'super_admin' ? (
              <div className="mt-2 flex items-center gap-2">
                {isEditingCode ? (
                  <div className="flex bg-white rounded overflow-hidden border border-primary w-full shadow-inner">
                    <input 
                      type="text"
                      className="w-full bg-transparent px-2 py-1 text-sm font-bold text-slate-800 outline-none uppercase"
                      value={localUnitCode}
                      onChange={e => setLocalUnitCode(e.target.value)}
                      onKeyDown={e => e.key === 'Enter' && handleSaveCode()}
                      autoFocus
                    />
                    <button onClick={handleSaveCode} className="px-1 text-primary hover:bg-slate-100 flex items-center justify-center border-l border-slate-200 material-symbols-outlined text-sm">check</button>
                    <button onClick={() => {setIsEditingCode(false); setLocalUnitCode(SCHOOL_CODE);}} className="px-1 text-slate-400 hover:bg-slate-100 flex items-center justify-center border-l border-slate-200 material-symbols-outlined text-sm">close</button>
                  </div>
                ) : (
                  <button onClick={() => setIsEditingCode(true)} className="flex items-start gap-1 group w-full text-left mt-1 hover:bg-slate-200/50 p-1 -ml-1 rounded transition-colors">
                    <span className="material-symbols-outlined text-[16px] text-primary mt-0.5">verified</span>
                    <span className="text-sm md:text-base font-bold text-primary truncate leading-tight flex-1">Soporte:<br/>{SCHOOL_CODE}</span>
                    <span className="material-symbols-outlined text-sm text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity">edit</span>
                  </button>
                )}
              </div>
            ) : (
              <p className="text-sm md:text-base font-bold text-primary mt-2 flex items-center gap-1 bg-primary/5 p-1 -ml-1 rounded">
                  <span className="material-symbols-outlined text-[16px]">verified</span>
                  {SCHOOL_CODE}
              </p>
            )}
        </div>
      </div>
      
      <nav className="flex-1 space-y-1 overflow-y-auto">
        {menuItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link 
              key={item.label}
              href={item.href}
              onClick={() => setIsOpen && setIsOpen(false)}
              className={`flex items-center gap-3 px-5 py-3 transition-all duration-200 group ${
                isActive 
                  ? 'text-primary font-black border-r-4 border-primary bg-white shadow-sm translate-x-1' 
                  : 'text-slate-600 font-bold hover:bg-slate-200/50'
              }`}
            >
              <span className="material-symbols-outlined text-xl">{item.icon}</span>
              <span className="font-body text-sm flex-1">{item.label}</span>
              {item.badge && (
                <span className="bg-red-500 text-white text-[10px] font-black px-1.5 py-0.5 rounded-full shadow-sm">
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="px-4 border-t border-outline-variant/10 pt-4 mt-2 flex flex-col gap-1">
        <Link 
          href="/dashboard/profile"
          onClick={() => setIsOpen && setIsOpen(false)}
          className={`flex items-center gap-3 px-5 py-3 transition-colors rounded-xl ${
            pathname === '/dashboard/profile' ? 'text-primary font-black bg-primary/5' : 'text-slate-600 font-bold hover:bg-slate-200/50'
          }`}
        >
          <span className="material-symbols-outlined text-xl">account_circle</span>
          <span className="font-body text-sm">Mi Perfil</span>
        </Link>
        <button 
          onClick={handleLogout}
          className="flex items-center gap-3 px-5 py-3 w-full text-left transition-colors rounded-xl text-error font-black hover:bg-error/10"
        >
          <span className="material-symbols-outlined text-xl">logout</span>
          <span className="font-body text-sm">Cerrar Sesión</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
