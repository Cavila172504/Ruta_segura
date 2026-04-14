"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, query, onSnapshot, doc, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const DashboardPage = () => {
  const [buses, setBuses] = useState([]);
  const [metrics, setMetrics] = useState({
    activeRoutes: 12,
    liveBuses: 8,
    studentsToday: 432,
    incidents: 2
  });

  const SCHOOL_CODE = 'CAD31';

  // Suscripción a Buses en Tiempo Real
  useEffect(() => {
    const busesRef = collection(db, 'companies', SCHOOL_CODE, 'live_tracking');
    
    const unsubscribe = onSnapshot(busesRef, (snapshot) => {
      const liveBuses = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setBuses(liveBuses);
      setMetrics(prev => ({ ...prev, liveBuses: liveBuses.length }));
    });

    return () => unsubscribe();
  }, []);

  return (
    <DashboardLayout title="Panel de Control">
      {/* Metric Cards Bento-style */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Rutas Activas */}
        <div className="bg-surface-container-lowest p-6 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-outline-variant/5">
          <div className="absolute top-0 left-0 w-1 h-full bg-primary"></div>
          <div className="flex justify-between items-start">
            <span className="text-slate-500 font-label text-xs uppercase tracking-wider font-semibold">Rutas Activas</span>
            <span className="material-symbols-outlined text-primary/40">route</span>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-4xl font-headline font-extrabold text-on-surface">{metrics.activeRoutes}</span>
            <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full flex items-center gap-0.5">
              <span className="material-symbols-outlined text-[14px]">trending_up</span>
              +2
            </span>
          </div>
        </div>

        {/* Buses en Marcha */}
        <div className="bg-surface-container-lowest p-6 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-outline-variant/5">
          <div className="absolute top-0 left-0 w-1 h-full bg-secondary"></div>
          <div className="flex justify-between items-start">
            <span className="text-slate-500 font-label text-xs uppercase tracking-wider font-semibold">Buses en marcha</span>
            <span className="material-symbols-outlined text-secondary/40">directions_bus</span>
          </div>
          <div className="mt-4 flex items-center justify-between">
            <span className="text-4xl font-headline font-extrabold text-on-surface">{buses.length.toString().padStart(2, '0')}</span>
            <div className="flex items-center gap-1.5 px-3 py-1 bg-primary/10 text-primary rounded-full">
              <div className="w-2 h-2 rounded-full bg-primary animate-pulse"></div>
              <span className="text-[10px] font-black uppercase tracking-tighter">Live</span>
            </div>
          </div>
        </div>

        {/* Alumnos Hoy */}
        <div className="bg-surface-container-lowest p-6 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-outline-variant/5">
          <div className="absolute top-0 left-0 w-1 h-full bg-tertiary-container"></div>
          <div className="flex justify-between items-start">
            <span className="text-slate-500 font-label text-xs uppercase tracking-wider font-semibold">Alumnos hoy</span>
            <span className="material-symbols-outlined text-tertiary/40">group</span>
          </div>
          <div className="mt-4">
            <span className="text-4xl font-headline font-extrabold text-on-surface">432</span>
            <div className="mt-2 w-full bg-surface-container h-1.5 rounded-full overflow-hidden">
              <div className="bg-primary h-full w-[86%]"></div>
            </div>
            <p className="text-[10px] text-slate-500 mt-1 font-medium">86% de capacidad total</p>
          </div>
        </div>

        {/* Incidentes */}
        <div className="bg-surface-container-lowest p-6 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-outline-variant/5">
          <div className="absolute top-0 left-0 w-1 h-full bg-error"></div>
          <div className="flex justify-between items-start">
            <span className="text-slate-500 font-label text-xs uppercase tracking-wider font-semibold">Incidentes</span>
            <span className="material-symbols-outlined text-error/40">warning</span>
          </div>
          <div className="mt-4 flex items-center justify-between">
            <span className="text-4xl font-headline font-extrabold text-error">02</span>
            <span className="text-[10px] font-bold text-error bg-error-container px-2 py-1 rounded">CRITICAL STATUS</span>
          </div>
        </div>
      </div>

      {/* Main Data Section */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8 mt-10">
        <div className="xl:col-span-2 space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="font-headline text-xl font-bold text-on-surface">Monitoreo Satelital ({SCHOOL_CODE})</h3>
          </div>
          <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-[0px_4px_20px_rgba(0,0,0,0.02)] border border-outline-variant/5">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container-low border-b border-outline-variant/10">
                  <th className="px-6 py-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">Ruta</th>
                  <th className="px-6 py-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">Conductor</th>
                  <th className="px-6 py-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">Estado</th>
                  <th className="px-6 py-4 text-[10px] font-bold text-slate-500 uppercase tracking-widest">Ubicación</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/5">
                {buses.length === 0 ? (
                  <tr>
                    <td colSpan="4" className="px-6 py-10 text-center text-slate-400">No hay unidades activas en este momento.</td>
                  </tr>
                ) : (
                  buses.map((bus) => (
                    <tr key={bus.id} className="group hover:bg-surface-container-low/50 transition-colors">
                      <td className="px-6 py-5">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary font-bold text-xs">
                            {bus.routeId || 'R--'}
                          </div>
                          <div>
                            <p className="text-sm font-bold text-on-surface">{bus.routeName || 'Ruta General'}</p>
                            <p className="text-[10px] text-slate-400">Placa: {bus.busId || 'N/A'}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-5">
                        <div className="flex items-center gap-2">
                          <img 
                            alt="Driver" 
                            className="w-7 h-7 rounded-full object-cover" 
                            src={bus.driverPhoto || "https://ui-avatars.com/api/?name=" + (bus.driverName || 'Driver') + "&background=random"} 
                          />
                          <span className="text-sm font-medium text-slate-600">{bus.driverName || 'Asignando...'}</span>
                        </div>
                      </td>
                      <td className="px-6 py-5">
                        <span className={`px-3 py-1 rounded-full text-[10px] font-bold ${
                          bus.status === 'on_route' ? 'bg-emerald-50 text-emerald-600' : 'bg-slate-100 text-slate-600'
                        }`}>
                          {bus.status === 'on_route' ? 'EN CAMINO' : 'INICIANDO'}
                        </span>
                      </td>
                      <td className="px-6 py-5">
                        <div className="flex items-center gap-2 text-slate-500">
                          <span className="material-symbols-outlined text-sm">location_on</span>
                          <span className="text-sm whitespace-nowrap overflow-hidden text-ellipsis max-w-[150px]">
                            {bus.lastStop || 'Ubicación actual'}
                          </span>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Alerts and Insights */}
        <div className="space-y-6">
          <h3 className="font-headline text-xl font-bold text-on-surface">Información de Sistema</h3>
          <div className="bg-primary/5 p-6 rounded-xl border border-primary/10">
            <h4 className="font-headline text-sm font-bold text-primary flex items-center gap-2">
              <span className="material-symbols-outlined text-lg">school</span>
              Código Vinculación
            </h4>
            <p className="text-2xl font-black text-primary mt-2">{SCHOOL_CODE}</p>
            <p className="text-xs text-slate-600 mt-2 leading-relaxed">
              Debe proporcionar este código a los padres de familia para que vinculen a sus hijos a esta institución desde la App Padre.
            </p>
          </div>
          
          <div className="bg-error-container/30 p-5 rounded-xl border-l-4 border-error relative overflow-hidden group">
            <div className="flex gap-4">
              <div className="bg-error-container p-2 rounded-lg h-fit text-error">
                <span className="material-symbols-outlined">minor_crash</span>
              </div>
              <div className="flex-1">
                <div className="flex justify-between items-start">
                  <p className="font-bold text-sm text-on-error-container">Monitoreo Activo</p>
                  <span className="text-[10px] font-bold text-error">LIVE</span>
                </div>
                <p className="text-xs text-on-error-container/80 mt-1 leading-relaxed">
                  Sistema de rastreo satelital funcionando correctamente para {buses.length} unidades.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default DashboardPage;
