"use client";
import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { auth } from '@/lib/firebase';
import { signOut } from 'firebase/auth';
import { useAuth } from '@/context/AuthContext';
import { clearServerSession } from '@/lib/session-auth';

const SUPER_ADMIN_PATHS = [
  '/dashboard/companies',
  '/dashboard/users',
  '/dashboard/global-reports',
  '/dashboard/profile',
];

const Sidebar = ({ profile, isOpen, setIsOpen, isCollapsed }) => {
  const pathname = usePathname();
  const router = useRouter();
  const { clearSupportContext } = useAuth();
  const isSuperAdmin = profile?.role === 'super_admin';

  const handleLogout = async () => {
    try {
      clearSupportContext();
      await clearServerSession();
      await signOut(auth);
      router.push('/login');
    } catch (error) {
      console.error('Error signing out', error);
    }
  };

  const superAdminMenu = [
    { icon: 'corporate_fare', label: 'Instituciones', href: '/dashboard/companies' },
    { icon: 'group_add', label: 'Usuarios Admin', href: '/dashboard/users' },
    { icon: 'analytics', label: 'Informes Globales', href: '/dashboard/global-reports' },
  ];

  const schoolAdminMenu = [
    { icon: 'dashboard', label: 'Dashboard', href: '/dashboard' },
    ...(profile?.role !== 'viewer'
      ? [
          { icon: 'person', label: 'Conductores', href: '/dashboard/drivers' },
          { icon: 'route', label: 'Rutas', href: '/dashboard/routes' },
          { icon: 'how_to_reg', label: 'Inscripciones', href: '/dashboard/students' },
          { icon: 'headset_mic', label: 'Soporte', href: '/dashboard/support' },
        ]
      : []),
    { icon: 'bar_chart', label: 'Informes', href: '/dashboard/reports' },
  ];

  const menuItems = isSuperAdmin ? superAdminMenu : schoolAdminMenu;

  return (
    <aside
      className={`fixed left-0 top-0 h-screen ${isCollapsed ? 'w-[80px]' : 'w-[240px]'} bg-slate-50 flex flex-col py-6 border-r border-outline-variant/10 z-50 transform transition-all duration-300 ease-in-out md:translate-x-0 ${isOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full'}`}
    >
      <button
        onClick={() => setIsOpen(false)}
        className="md:hidden absolute top-4 right-4 text-slate-400 hover:text-slate-600"
      >
        <span className="material-symbols-outlined text-xl">close</span>
      </button>

      <div className={`px-4 mb-10 mt-2 md:mt-0 ${isCollapsed ? 'text-center' : ''}`}>
        <h1 className={`font-bold tracking-tight text-primary font-headline italic ${isCollapsed ? 'text-xl' : 'text-2xl'}`}>
          {isCollapsed ? 'RS' : 'RutaSegura'}
        </h1>
        {!isCollapsed && (
          <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest mt-1">
            {isSuperAdmin ? 'Supervisión Global' : 'Administración Colegio'}
          </p>
        )}
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto">
        {menuItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setIsOpen && setIsOpen(false)}
              title={isCollapsed ? item.label : ''}
              className={`relative flex items-center ${isCollapsed ? 'justify-center px-0' : 'gap-3 px-5'} py-3 transition-all ${
                isActive
                  ? 'text-primary font-black border-r-4 border-primary bg-white shadow-sm'
                  : 'text-slate-600 font-bold hover:bg-slate-200/50'
              }`}
            >
              <span className="material-symbols-outlined text-xl">{item.icon}</span>
              {!isCollapsed && <span className="text-sm">{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      <div className="px-4 border-t border-outline-variant/10 pt-4 mt-2 flex flex-col gap-1">
        <Link
          href="/dashboard/profile"
          className={`flex items-center ${isCollapsed ? 'justify-center' : 'gap-3 px-5'} py-3 rounded-xl text-slate-600 font-bold hover:bg-slate-200/50`}
        >
          <span className="material-symbols-outlined text-xl">account_circle</span>
          {!isCollapsed && <span className="text-sm">Mi Perfil</span>}
        </Link>
        <button
          onClick={handleLogout}
          className={`flex items-center ${isCollapsed ? 'justify-center' : 'gap-3 px-5'} py-3 w-full text-left rounded-xl text-error font-black hover:bg-error/10`}
        >
          <span className="material-symbols-outlined text-xl">logout</span>
          {!isCollapsed && <span className="text-sm">Cerrar Sesión</span>}
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
