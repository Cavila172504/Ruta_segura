"use client";
import React, { useState, useEffect, useCallback } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, where, doc, deleteDoc, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import dynamic from 'next/dynamic';

const LiveMap = dynamic(() => import('@/components/dashboard/LiveMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-[520px] bg-slate-100 animate-pulse rounded-2xl flex items-center justify-center text-slate-400 font-bold uppercase tracking-widest">
      Iniciando Mapa Satelital...
    </div>
  ),
});

const DashboardPage = () => {
  const { profile, loading: authLoading, SCHOOL_CODE } = useAuth();

  const [buses, setBuses]       = useState([]);
  const [drivers, setDrivers]   = useState([]);
  const [students, setStudents] = useState([]);
  const [routes, setRoutes]     = useState([]);
  const [incidents, setIncidents] = useState([]);
  const [showStudents, setShowStudents] = useState(true);
  const [schoolInfo, setSchoolInfo] = useState(null);

  useEffect(() => {
    if (authLoading || !SCHOOL_CODE) return;

    const companyUnsub = onSnapshot(doc(db, 'companies', SCHOOL_CODE), (snap) => {
      if (snap.exists()) {
        const d = snap.data();
        setSchoolInfo({
          name: d.name || SCHOOL_CODE,
          address: d.schoolAddress || '',
          lat: d.schoolLat ?? null,
          lng: d.schoolLng ?? null,
        });
      }
    });

    // 1. Buses / live_tracking  (solo los que tengan GPS real)
    const busUnsub = onSnapshot(
      collection(db, 'companies', SCHOOL_CODE, 'live_tracking'),
      (snap) => {
        const live = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .filter(b => (b.lat != null || b.latitude != null) && (b.lng != null || b.longitude != null));
        setBuses(live);
      }
    );

    // 2. Conductores registrados (fuente de verdad para el conteo)
    const driverUnsub = onSnapshot(
      collection(db, 'companies', SCHOOL_CODE, 'drivers'),
      (snap) => setDrivers(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );

    // 3. Estudiantes registrados
    const stuUnsub = onSnapshot(
      collection(db, 'companies', SCHOOL_CODE, 'students'),
      (snap) => setStudents(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );

    // 3. Rutas
    const routesUnsub = onSnapshot(
      collection(db, 'companies', SCHOOL_CODE, 'routes'),
      (snap) => setRoutes(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );

    // 4. Incidentes / reports
    const incUnsub = onSnapshot(
      collection(db, 'companies', SCHOOL_CODE, 'incidents'),
      (snap) => setIncidents(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );

    return () => {
      companyUnsub();
      busUnsub();
      driverUnsub();
      stuUnsub();
      routesUnsub();
      incUnsub();
    };
  }, [SCHOOL_CODE, authLoading]);

  // Métricas derivadas en tiempo real
  const activeBuses    = buses.filter(b => b.status === 'on_route' || b.status === 'active');
  const activeRoutes   = routes.filter(r => r.status === 'active' || r.status === 'on_route');
  const openIncidents  = incidents.filter(i => i.status !== 'resolved');

  return (
    <DashboardLayout title="Panel de Control">

      {/* ── METRIC CARDS ─────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">

        {/* Rutas Activas */}
        <div className="bg-white p-5 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-slate-100">
          <div className="absolute top-0 left-0 w-1 h-full bg-primary rounded-l-xl"></div>
          <div className="flex justify-between items-start pl-2">
            <span className="text-slate-500 text-[10px] uppercase tracking-wider font-bold">Rutas Activas</span>
            <span className="material-symbols-outlined text-primary/40 text-xl">route</span>
          </div>
          <div className="mt-2 pl-2 flex items-baseline gap-2">
            <span className="text-3xl font-headline font-extrabold text-on-surface">{routes.length}</span>
            <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
              {activeRoutes.length} activas
            </span>
          </div>
        </div>

        {/* Conductores Registrados */}
        <div className="bg-white p-5 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-slate-100">
          <div className="absolute top-0 left-0 w-1 h-full bg-secondary rounded-l-xl"></div>
          <div className="flex justify-between items-start pl-2">
            <span className="text-slate-500 text-[10px] uppercase tracking-wider font-bold">Conductores</span>
            <span className="material-symbols-outlined text-secondary/40 text-xl">directions_bus</span>
          </div>
          <div className="mt-2 pl-2 flex items-center justify-between">
            <span className="text-3xl font-headline font-extrabold text-on-surface">
              {drivers.length.toString().padStart(2, '0')}
            </span>
            <div className="flex flex-col items-end gap-1">
              <div className="flex items-center gap-1.5 px-2 py-1 bg-primary/10 text-primary rounded-lg shadow-sm">
                <div className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse"></div>
                <span className="text-[10px] font-black uppercase">{buses.length} Live</span>
              </div>
            </div>
          </div>
        </div>

        {/* Alumnos Registrados */}
        <div className="bg-white p-5 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-slate-100">
          <div className="absolute top-0 left-0 w-1 h-full bg-emerald-500 rounded-l-xl"></div>
          <div className="flex justify-between items-start pl-2">
            <span className="text-slate-500 text-[10px] uppercase tracking-wider font-bold">Estudiantes</span>
            <span className="material-symbols-outlined text-emerald-400/60 text-xl">group</span>
          </div>
          <div className="mt-2 pl-2">
            <span className="text-3xl font-headline font-extrabold text-on-surface">{students.length}</span>
            <div className="mt-2 w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
              <div
                className="bg-emerald-500 h-full transition-all duration-700"
                style={{ width: students.length > 0 ? '100%' : '0%' }}
              ></div>
            </div>
            <p className="text-[10px] text-slate-400 mt-1 font-bold">Vinculados al código {SCHOOL_CODE}</p>
          </div>
        </div>

        {/* Incidentes */}
        <div className="bg-white p-5 rounded-xl relative overflow-hidden flex flex-col justify-between group hover:scale-[1.02] transition-transform duration-300 shadow-sm border border-slate-100">
          <div className={`absolute top-0 left-0 w-1 h-full rounded-l-xl ${openIncidents.length > 0 ? 'bg-error' : 'bg-slate-300'}`}></div>
          <div className="flex justify-between items-start pl-2">
            <span className="text-slate-500 text-[10px] uppercase tracking-wider font-bold">Incidentes</span>
            <span className={`material-symbols-outlined text-xl ${openIncidents.length > 0 ? 'text-error/50' : 'text-slate-300'}`}>warning</span>
          </div>
          <div className="mt-2 pl-2 flex items-center justify-between">
            <span className={`text-3xl font-headline font-extrabold ${openIncidents.length > 0 ? 'text-error' : 'text-slate-400'}`}>
              {openIncidents.length.toString().padStart(2, '0')}
            </span>
            {openIncidents.length > 0 ? (
              <span className="text-[10px] font-bold text-error bg-error-container px-2 py-0.5 rounded">SIN RESOLVER</span>
            ) : (
              <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded">TODO OK</span>
            )}
          </div>
        </div>

        {/* Botón de Limpieza (Solo Super Admin) */}
        {profile?.role === 'super_admin' && (
          <button 
            onClick={async () => {
              if(!window.confirm('¿Deseas limpiar todas las sesiones? Solo se eliminarán del mapa, los choferes volverán a aparecer al reconectarse.')) return;
              const busesRef = collection(db, 'companies', SCHOOL_CODE, 'active_buses');
              const qSnap = await getDocs(busesRef);
              qSnap.forEach(async (d) => {
                await deleteDoc(doc(db, 'companies', SCHOOL_CODE, 'active_buses', d.id));
              });
              alert('Mapa Limpiado Exitosamente');
            }}
            className="mt-4 flex items-center gap-2 bg-slate-900 border border-slate-800 text-slate-400 hover:text-white px-5 py-2.5 rounded-xl font-black text-[10px] uppercase tracking-widest transition-all shadow-xl group self-start"
          >
            <span className="material-symbols-outlined text-base group-hover:rotate-180 transition-transform">refresh</span>
            Limpiar Sesiones Muertas (Mantenimiento)
          </button>
        )}
      </div>

      {/* ── MAPA + SIDEBAR INFO ──────────────────────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8 mt-10">

        {/* Columna Mapa */}
        <div className="xl:col-span-2 space-y-6">

          {/* Cabecera con toggles */}
          <div className="flex items-center justify-between flex-wrap gap-4">
            <h3 className="font-headline text-xl font-bold text-on-surface uppercase tracking-tight">
              Monitoreo Satelital — <span className="text-primary">{SCHOOL_CODE}</span>
            </h3>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 bg-primary rounded-full"></div>
                <span className="text-xs font-bold text-slate-500 uppercase tracking-widest">Conductores</span>
              </div>
              <button
                onClick={() => setShowStudents(s => !s)}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-bold transition-all border ${
                  showStudents
                    ? 'bg-secondary text-white border-secondary'
                    : 'bg-white text-secondary border-secondary/30 hover:bg-secondary/10'
                }`}
              >
                <div className="w-2.5 h-2.5 rounded-full bg-current"></div>
                {showStudents ? 'Paradas Visibles' : 'Mostrar Paradas'}
              </button>
            </div>
          </div>

          {/* MAPA */}
          <LiveMap
            buses={getFilteredActiveBuses(buses)}
            students={showStudents ? students : []}
            schoolCenter={{ lat: schoolInfo?.lat, lng: schoolInfo?.lng }}
            schoolName={schoolInfo?.name}
            schoolAddress={schoolInfo?.address}
          />

          {/* ── TABLA ESTADO DE FLOTA ── */}
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-100 mt-6">
            <div className="p-5 border-b border-slate-100 bg-slate-50/70 flex items-center justify-between">
              <h4 className="text-sm font-black text-on-surface uppercase tracking-widest">Estado de Flota</h4>
              <span className="text-xs text-slate-400 font-semibold">{getFilteredActiveBuses(buses).length} unidad(es) conectada(s)</span>
            </div>
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-100">
                  <th className="px-5 py-3 text-xs font-bold text-slate-400 uppercase tracking-widest">Conductor</th>
                  <th className="px-5 py-3 text-xs font-bold text-slate-400 uppercase tracking-widest">Estado</th>
                  <th className="px-5 py-3 text-xs font-bold text-slate-400 uppercase tracking-widest">Velocidad</th>
                  <th className="px-5 py-3 text-xs font-bold text-slate-400 uppercase tracking-widest">Última Actualización</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {getFilteredActiveBuses(buses).length === 0 ? (
                  <tr>
                    <td colSpan="4" className="px-6 py-10 text-center text-slate-400">
                      No hay unidades activas en este momento.
                    </td>
                  </tr>
                ) : (
                  getFilteredActiveBuses(buses).map((bus) => {
                    const isActive = bus.status === 'on_route';
                    const updatedAt = bus.updatedAt?.toDate?.() || bus.timestamp?.toDate?.();
                    return (
                      <tr key={bus.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-3">
                            <img
                              alt="Driver"
                              className="w-9 h-9 rounded-full object-cover border-2 border-primary/10"
                              src={`https://ui-avatars.com/api/?name=${bus.driverName || 'D'}&background=3b309e&color=fff`}
                            />
                            <div>
                              <p className="text-sm font-bold text-on-surface">{bus.driverName || 'Asignando...'}</p>
                              <p className="text-xs text-slate-400">ID: {bus.id}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          <span className={`px-3 py-1.5 rounded-full text-xs font-bold ${
                            isActive ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'
                          }`}>
                            {isActive ? '🟢 EN CAMINO' : '⚪ INICIANDO'}
                          </span>
                        </td>
                        <td className="px-5 py-4 text-sm font-semibold text-slate-600">
                          {bus.speed != null ? `${parseFloat(bus.speed).toFixed(1)} km/h` : '—'}
                        </td>
                        <td className="px-5 py-4 text-xs text-slate-400">
                          {updatedAt ? updatedAt.toLocaleTimeString('es-EC', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : 'Sin datos'}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* ── COLUMNA DERECHA INFO ── */}
        <div className="space-y-5">
          <h3 className="font-headline text-xl font-bold text-on-surface">Información de Sistema</h3>

          {/* Código de Vinculación */}
          <div className="bg-primary/5 p-5 rounded-2xl border border-primary/15">
            <h4 className="font-headline text-xs font-bold text-primary flex items-center gap-1.5">
              <span className="material-symbols-outlined text-base">school</span>
              Código de Vinculación
            </h4>
            <p className="text-2xl font-black text-primary mt-1 tracking-widest">{SCHOOL_CODE}</p>
            <p className="text-[11px] text-slate-600 mt-2 leading-relaxed">
              Comparte este código a los padres de familia para que vinculen a sus hijos desde la <strong>App Padre</strong>.
            </p>
          </div>

          {/* Estado del monitoreo */}
          <div className={`p-5 rounded-2xl border-l-4 ${buses.length > 0 ? 'bg-emerald-50 border-emerald-500' : 'bg-slate-50 border-slate-300'}`}>
            <div className="flex gap-3">
              <div className={`p-2 rounded-lg h-fit ${buses.length > 0 ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-400'}`}>
                <span className="material-symbols-outlined">{buses.length > 0 ? 'gps_fixed' : 'gps_not_fixed'}</span>
              </div>
              <div className="flex-1">
                <div className="flex justify-between items-center">
                  <p className="font-bold text-sm text-on-surface">Monitoreo {buses.length > 0 ? 'Activo' : 'En Espera'}</p>
                  {buses.length > 0 && <span className="text-xs font-black text-emerald-600 animate-pulse">LIVE</span>}
                </div>
                <p className="text-xs text-slate-600 mt-1 leading-relaxed">
                  {buses.length > 0
                    ? `Rastreo GPS funcionando — ${buses.length} conductor(es) conectado(s).`
                    : 'Ningún conductor ha iniciado sesión aún.'}
                </p>
              </div>
            </div>
          </div>

          {/* Resumen Estudiantes */}
          <div className="bg-white p-4 rounded-2xl border border-slate-100 shadow-sm">
            <h4 className="font-bold text-xs text-slate-500 uppercase tracking-widest mb-1">
              Estudiantes Vinculados
            </h4>
            <p className="text-2xl font-black text-secondary">{students.length}</p>
            <p className="text-[10px] text-slate-400 mt-0.5">
              {students.filter(s => s.stopLat && s.stopLng).length} con parada registrada en el mapa.
            </p>
          </div>

          {/* Incidentes Recientes */}
          {openIncidents.length > 0 && (
            <div className="bg-error-container/20 p-5 rounded-2xl border border-error/20">
              <h4 className="font-bold text-sm text-error flex items-center gap-2 mb-3">
                <span className="material-symbols-outlined text-lg">warning</span>
                Incidentes Abiertos ({openIncidents.length})
              </h4>
              <div className="space-y-2">
                {openIncidents.slice(0, 3).map(inc => (
                  <div key={inc.id} className="bg-white p-3 rounded-xl text-xs text-slate-600 border border-error/10">
                    <p className="font-bold text-error">{inc.type || 'Incidente'}</p>
                    <p className="text-slate-500 mt-0.5">{inc.description || '—'}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

// Componente para filtrar buses fantasmas (inactivos > 10 min)
const getFilteredActiveBuses = (buses) => {
  const now = new Date().getTime();
  const TEN_MINUTES = 10 * 60 * 1000;
  
  return buses.filter(bus => {
    // Usar lastUpdated (App) o lastUpdate o timestamp
    const stamp = bus.lastUpdated || bus.lastUpdate || bus.timestamp;
    
    // Si no hay ninguna fecha registrada, no mostrarlo por seguridad (o dejarlo expirar)
    if (!stamp) return false; 
    
    // Convertir de Firestore Timestamp a ms
    const updateTime = stamp.toDate ? stamp.toDate().getTime() : now;
    return (now - updateTime) < TEN_MINUTES;
  });
};

export default DashboardPage;
