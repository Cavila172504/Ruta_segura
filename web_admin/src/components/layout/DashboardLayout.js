"use client";
import React from 'react';
import Sidebar from './Sidebar';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

const DashboardLayout = ({ children, title = "Dashboard" }) => {
  const { user, profile, loading } = useAuth();
  const router = useRouter();
  const [isSidebarOpen, setIsSidebarOpen] = React.useState(false);

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
    <div className="flex bg-surface min-h-screen relative">
      {/* Overlay for mobile sidebar */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-slate-900/50 z-40 md:hidden backdrop-blur-sm"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar fixed from design */}
      <Sidebar profile={profile} isOpen={isSidebarOpen} setIsOpen={setIsSidebarOpen} />
      
      {/* Main Wrapper */}
      <div className="flex-1 flex flex-col md:ml-[240px] ml-0 min-w-0 transition-all duration-300">
        {/* TopNavBar from design */}
        <header className="sticky top-0 z-30 w-full bg-white/80 backdrop-blur-md shadow-[0px_10px_30px_rgba(83,74,183,0.06)] flex justify-between items-center h-16 px-4 md:px-8 border-b border-outline-variant/10">
          <div className="flex items-center gap-3">
            <button 
              onClick={() => setIsSidebarOpen(true)}
              className="md:hidden material-symbols-outlined text-slate-600 hover:text-primary transition-colors p-2"
            >
              menu
            </button>
            <h2 className="font-headline text-base md:text-lg font-bold text-primary truncate max-w-[200px] md:max-w-none">{title}</h2>
          </div>
          <div className="flex items-center gap-4 md:gap-6">
            <div className="flex items-center gap-4 text-slate-600 hidden sm:flex">
              <button className="material-symbols-outlined hover:scale-110 duration-150 text-primary">notifications</button>
            </div>
            <div className="flex items-center gap-3 pl-0 sm:pl-6 sm:border-l border-outline-variant/20">
              <div className="text-right hidden sm:block">
                <p className="text-xs font-bold font-body text-on-surface">{profile?.name || 'Admin User'}</p>
                <p className="text-[10px] text-slate-500 uppercase tracking-tighter">{profile?.role === 'super_admin' ? 'Supervisión Global' : 'Administración'}</p>
              </div>
              <img 
                alt="User Avatar" 
                className="w-8 h-8 md:w-10 md:h-10 rounded-full object-cover border-2 border-primary/10 shadow-sm" 
                src={profile?.photoUrl || "https://ui-avatars.com/api/?name=" + (profile?.name || 'Admin') + "&background=3b309e&color=fff"} 
              />
            </div>
          </div>
        </header>

        {/* Content Canvas */}
        <main className="p-4 md:p-8 space-y-6 md:space-y-10 max-w-[1600px] mx-auto w-full overflow-x-hidden">
          {children}
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;
