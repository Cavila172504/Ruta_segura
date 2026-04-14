"use client";
import React from 'react';
import Sidebar from './Sidebar';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

const DashboardLayout = ({ children, title = "Dashboard" }) => {
  const { user, profile, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-surface">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!user) return null;

  return (
    <div className="flex bg-surface min-h-screen">
      {/* Sidebar fixed from design */}
      <Sidebar profile={profile} />
      
      {/* Main Wrapper */}
      <div className="flex-1 flex flex-col ml-[240px]">
        {/* TopNavBar from design */}
        <header className="sticky top-0 z-40 w-full bg-white/80 backdrop-blur-md shadow-[0px_10px_30px_rgba(83,74,183,0.06)] flex justify-between items-center h-16 px-8">
          <h2 className="font-headline text-lg font-bold text-primary">{title}</h2>
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-4 text-slate-600">
              <button className="material-symbols-outlined hover:scale-110 duration-150 text-primary">notifications</button>
            </div>
            <div className="flex items-center gap-3 pl-6 border-l border-outline-variant/20">
              <div className="text-right">
                <p className="text-xs font-bold font-body text-on-surface">{profile?.name || 'Admin User'}</p>
                <p className="text-[10px] text-slate-500 uppercase tracking-tighter">{profile?.role === 'super_admin' ? 'Supervisión Global' : 'Administración Colegio'}</p>
              </div>
              <img 
                alt="User Avatar" 
                className="w-10 h-10 rounded-full object-cover border-2 border-primary/10" 
                src={profile?.photoUrl || "https://ui-avatars.com/api/?name=" + (profile?.name || 'Admin') + "&background=3b309e&color=fff"} 
              />
            </div>
          </div>
        </header>

        {/* Content Canvas */}
        <main className="p-8 space-y-10 max-w-[1600px] mx-auto w-full">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;
