"use client";
import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

const Sidebar = ({ profile }) => {
  const pathname = usePathname();

  const menuItems = [
    { icon: 'dashboard', label: 'Dashboard', href: '/dashboard' },
    { icon: 'person', label: 'Conductores', href: '/dashboard/drivers' },
    { icon: 'route', label: 'Rutas', href: '/dashboard/routes' },
    { icon: 'school', label: 'Estudiantes', href: '/dashboard/students' },
    { icon: 'analytics', label: 'Informes', href: '/dashboard/reports' },
  ];

  return (
    <aside className="fixed left-0 top-0 h-screen w-[240px] bg-slate-50 flex flex-col py-6 border-r border-outline-variant/10">
      <div className="px-6 mb-10">
        <h1 className="text-xl font-bold tracking-tight text-primary font-headline">RutaSegura</h1>
        <div className="mt-1 flex flex-col">
            <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest leading-none">School Admin</p>
            <p className="text-[14px] font-bold text-primary mt-1 flex items-center gap-1">
                <span className="material-symbols-outlined text-sm">verified</span>
                CAD31
            </p>
        </div>
      </div>
      
      <nav className="flex-1 space-y-1">
        {menuItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link 
              key={item.label}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 transition-all duration-200 ${
                isActive 
                  ? 'text-primary font-bold border-r-4 border-primary bg-white/50 translate-x-1' 
                  : 'text-slate-500 font-medium hover:bg-slate-200/50'
              }`}
            >
              <span className="material-symbols-outlined">{item.icon}</span>
              <span className="font-body text-sm">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto px-4 border-t border-outline-variant/10 pt-6">
        <Link 
          href="/dashboard/profile"
          className={`flex items-center gap-3 px-4 py-3 transition-colors rounded-xl ${
            pathname === '/dashboard/profile' ? 'text-primary font-bold' : 'text-slate-500 font-medium hover:bg-slate-200/50'
          }`}
        >
          <span className="material-symbols-outlined">account_circle</span>
          <span className="font-body text-sm">Mi Perfil</span>
        </Link>
      </div>
    </aside>
  );
};

export default Sidebar;
