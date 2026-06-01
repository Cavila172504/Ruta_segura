"use client";
import React, { useEffect } from 'react';
import Sidebar from './Sidebar';
import { useAuth } from '@/context/AuthContext';
import { useRouter, usePathname } from 'next/navigation';

const SUPER_ADMIN_ALLOWED = [
  '/dashboard/companies',
  '/dashboard/users',
  '/dashboard/global-reports',
  '/dashboard/profile',
];

const SCHOOL_ONLY_PATHS = [
  '/dashboard',
  '/dashboard/drivers',
  '/dashboard/routes',
  '/dashboard/students',
  '/dashboard/support',
  '/dashboard/reports',
];

const DashboardLayout = ({ children, title = "Dashboard" }) => {
  const { user, profile, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [isSidebarOpen, setIsSidebarOpen] = React.useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = React.useState(false);

  useEffect(() => {
    if (!loading && !user) router.push('/login');
  }, [user, loading, router]);

  useEffect(() => {
    if (loading || profile?.role !== 'super_admin') return;

    const isSchoolRoute = SCHOOL_ONLY_PATHS.some(
      (p) => pathname === p || (p !== '/dashboard' && pathname.startsWith(p + '/'))
    ) || pathname === '/dashboard';

    const isAllowed = SUPER_ADMIN_ALLOWED.some(
      (p) => pathname === p || pathname.startsWith(p + '/')
    );

    if (isSchoolRoute || !isAllowed) {
      router.replace('/dashboard/companies');
    }
  }, [loading, profile, pathname, router]);

  const handleMenuClick = () => {
    if (typeof window !== 'undefined' && window.matchMedia('(min-width: 768px)').matches) {
      setIsSidebarCollapsed((prev) => !prev);
    } else {
      setIsSidebarOpen(true);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-surface">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!user) return null;

  return (
    <div className="flex bg-surface min-h-screen relative">
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-slate-900/50 z-40 md:hidden backdrop-blur-sm"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      <Sidebar
        profile={profile}
        isOpen={isSidebarOpen}
        setIsOpen={setIsSidebarOpen}
        isCollapsed={isSidebarCollapsed}
      />

      <div
        className={`flex-1 flex flex-col ${isSidebarCollapsed ? 'md:ml-[80px]' : 'md:ml-[240px]'} ml-0 min-w-0 transition-all duration-300`}
      >
        <header className="sticky top-0 z-30 w-full bg-white/80 backdrop-blur-md shadow-sm flex justify-between items-center h-16 px-4 md:px-8 border-b border-outline-variant/10">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={handleMenuClick}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-600"
              aria-label="Menú de navegación"
            >
              <span className="material-symbols-outlined">menu</span>
            </button>
            <h2 className="font-headline text-base md:text-lg font-bold text-primary truncate">{title}</h2>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-right hidden sm:block">
              <p className="text-xs font-bold">{profile?.name || 'Admin'}</p>
              <p className="text-[10px] text-slate-500 uppercase">
                {profile?.role === 'super_admin' ? 'Super Admin' : 'Administración'}
              </p>
            </div>
            <img
              alt=""
              className="w-10 h-10 rounded-full border-2 border-primary/10"
              src={
                profile?.photoUrl ||
                `https://ui-avatars.com/api/?name=${encodeURIComponent(profile?.name || 'Admin')}&background=3b309e&color=fff`
              }
            />
          </div>
        </header>

        <main className="p-4 md:p-8 max-w-[1600px] mx-auto w-full">{children}</main>
      </div>
    </div>
  );
};

export default DashboardLayout;
