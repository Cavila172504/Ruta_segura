"use client";
import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import DashboardLayout from '@/components/layout/DashboardLayout';
import KpiCard from '@/components/dashboard/KpiCard';
import LiveRoutesPanel from '@/components/dashboard/LiveRoutesPanel';
import { collection, onSnapshot, doc, deleteDoc, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import dynamic from 'next/dynamic';

function parseLatLng(value) {
  if (value == null || value === '') return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const n = Number(value.trim().replace(',', '.'));
    return Number.isFinite(n) ? n : null;
  }
  if (typeof value === 'object') {
    if (typeof value.latitude === 'number') return value.latitude;
    if (typeof value.lat === 'number') return value.lat;
    if (typeof value.longitude === 'number') return value.longitude;
    if (typeof value.lng === 'number') return value.lng;
  }
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

const LiveMap = dynamic(() => import('@/components/dashboard/LiveMap'), {
  ssr: false,
  loading: () => (
    <div
      className="w-full bg-slate-100 animate-pulse rounded-2xl flex items-center justify-center text-slate-400 font-bold uppercase tracking-widest"
      style={{ height: 'min(68vh, 620px)' }}
    >
      Iniciando mapa...
    </div>
  ),
});

const getFilteredActiveBuses = (buses) => {
  const now = Date.now();
  const TEN_MINUTES = 10 * 60 * 1000;

  return buses.filter((bus) => {
    const stamp = bus.lastUpdated || bus.lastUpdate || bus.timestamp;
    if (!stamp) return false;
    const updateTime = stamp.toDate ? stamp.toDate().getTime() : now;
    return now - updateTime < TEN_MINUTES;
  });
};

const DashboardPage = () => {
  const { profile, loading: authLoading, SCHOOL_CODE } = useAuth();
  const toast = useToast();

  const [buses, setBuses] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [students, setStudents] = useState([]);
  const [routes, setRoutes] = useState([]);
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
          lat: parseLatLng(d.schoolLat),
          lng: parseLatLng(d.schoolLng),
        });
      }
    });

    const busUnsub = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'live_tracking'), (snap) => {
      const live = snap.docs
        .map((d) => ({ id: d.id, ...d.data() }))
        .filter((b) => (b.lat != null || b.latitude != null) && (b.lng != null || b.longitude != null));
      setBuses(live);
    });

    const driverUnsub = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'drivers'), (snap) =>
      setDrivers(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
    );

    const stuUnsub = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'students'), (snap) =>
      setStudents(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
    );

    const routesUnsub = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'routes'), (snap) =>
      setRoutes(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
    );

    const incUnsub = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'incident_reports'), (snap) =>
      setIncidents(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
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

  const liveBuses = useMemo(() => getFilteredActiveBuses(buses), [buses]);
  const activeOnRoute = liveBuses.filter((b) => b.status === 'on_route' || b.status === 'active');
  const openIncidents = incidents.filter((i) => i.status !== 'resolved');

  const routeByDriver = useMemo(() => {
    const map = {};
    routes.forEach((r) => {
      const did = r.driverId || r.entryDriver;
      if (!did) return;
      map[did] = {
        id: r.id,
        name: r.name || r.routeName || r.id,
        studentCount: 0,
      };
    });
    students.forEach((s) => {
      const did = s.driverId;
      if (!did) return;
      if (!map[did]) {
        map[did] = { id: did, name: s.assignedRoute || 'Sin nombre', studentCount: 0 };
      }
      map[did].studentCount += 1;
    });
    return map;
  }, [routes, students]);

  const studentsEnRoute = useMemo(() => {
    const activeDriverIds = new Set(activeOnRoute.map((b) => b.driverId || b.id));
    return students.filter((s) => activeDriverIds.has(s.driverId));
  }, [students, activeOnRoute]);

  const delayIncidents = openIncidents.filter(
    (i) => i.type === 'delay' || i.type === 'retraso' || String(i.type || '').toLowerCase().includes('retraso')
  );
  const speedIncidents = openIncidents.filter(
    (i) => i.type === 'speed' || i.type === 'velocidad' || String(i.type || '').toLowerCase().includes('veloc')
  );

  const onTimePercent = useMemo(() => {
    if (activeOnRoute.length === 0) return 100;
    const delayedDrivers = new Set(delayIncidents.map((i) => i.driverId).filter(Boolean));
    const onTime = activeOnRoute.filter((b) => !delayedDrivers.has(b.driverId || b.id)).length;
    return Math.round((onTime / activeOnRoute.length) * 1000) / 10;
  }, [activeOnRoute, delayIncidents]);

  const liveRouteRows = useMemo(
    () =>
      liveBuses.map((bus) => {
        const did = bus.driverId || bus.id;
        const routeInfo = routeByDriver[did] || {};
        const hasDelay = delayIncidents.some((i) => i.driverId === did);
        const hasSpeed = speedIncidents.some((i) => i.driverId === did);
        const isActive = bus.status === 'on_route' || bus.status === 'active';

        let status = 'idle';
        let statusLabel = 'Detenido';
        if (hasSpeed) {
          status = 'alert';
          statusLabel = 'Alerta';
        } else if (hasDelay) {
          status = 'delay';
          statusLabel = 'Retraso';
        } else if (isActive) {
          status = 'on_time';
          statusLabel = 'A tiempo';
        }

        const routeName = routeInfo.name ? String(routeInfo.name) : null;
        return {
          id: bus.id,
          label: routeName ? `R-${routeName.slice(0, 10)}` : `Unidad ${String(bus.id).slice(0, 6)}`,
          driverName: bus.driverName || 'Conductor',
          status,
          statusLabel,
        };
      }),
    [liveBuses, routeByDriver, delayIncidents, speedIncidents]
  );

  const routesWithLive = routes.filter((r) => {
    const did = r.driverId || r.entryDriver;
    return did && liveBuses.some((b) => (b.driverId || b.id) === did);
  });

  return (
    <DashboardLayout title="Panel de Control">
      {/* ── 6 KPI CARDS (estilo referencia SaaS) ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6 gap-4 mb-6">
        <KpiCard
          label="Rutas activas"
          value={routes.length}
          subtitle={`${routesWithLive.length || activeOnRoute.length} en vivo`}
          icon="route"
          accent="blue"
        />
        <KpiCard
          label="Estudiantes"
          value={students.length.toLocaleString('es-EC')}
          subtitle={`${studentsEnRoute.length} en ruta`}
          icon="groups"
          accent="blue"
        />
        <KpiCard
          label="Unidades"
          value={drivers.length || liveBuses.length}
          subtitle={`${liveBuses.length} conectadas`}
          icon="directions_bus"
          accent="teal"
        />
        <KpiCard
          label="Conductores"
          value={drivers.length}
          subtitle={`${activeOnRoute.length} en servicio`}
          icon="badge"
          accent="green"
        />
        <KpiCard
          label="Puntualidad"
          value={`${onTimePercent}%`}
          subtitle={delayIncidents.length > 0 ? `${delayIncidents.length} retraso(s)` : 'Sin retrasos hoy'}
          icon="check_circle"
          accent="green"
        />
        <KpiCard
          label="Alertas"
          value={openIncidents.length}
          subtitle={
            openIncidents.length > 0
              ? `${delayIncidents.length} retraso · ${speedIncidents.length} velocidad`
              : 'Todo en orden'
          }
          icon="warning"
          accent="amber"
        />
      </div>

      {/* ── Cabecera del mapa ── */}
      <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
        <div>
          <h2 className="text-lg font-black text-slate-800 tracking-tight">
            Monitoreo en tiempo real
          </h2>
          <p className="text-xs text-slate-500 font-medium mt-0.5">
            {schoolInfo?.name || SCHOOL_CODE} · Código <span className="font-black text-[#4361ee]">{SCHOOL_CODE}</span>
          </p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            onClick={() => setShowStudents((s) => !s)}
            className={`flex items-center gap-2 px-3 py-2 rounded-xl text-[11px] font-black uppercase tracking-wide transition-all border ${
              showStudents
                ? 'bg-[#4361ee] text-white border-[#4361ee]'
                : 'bg-white text-slate-600 border-slate-200 hover:border-[#4361ee]/40'
            }`}
          >
            <span className="material-symbols-outlined text-base">home_pin</span>
            {showStudents ? 'Paradas visibles' : 'Mostrar paradas'}
          </button>
          {profile?.role === 'super_admin' && (
            <button
              type="button"
              onClick={async () => {
                if (
                  !window.confirm(
                    '¿Limpiar sesiones inactivas del mapa? Los conductores reaparecerán al reconectarse.'
                  )
                )
                  return;
                const busesRef = collection(db, 'companies', SCHOOL_CODE, 'active_buses');
                const qSnap = await getDocs(busesRef);
                await Promise.all(
                  qSnap.docs.map((d) => deleteDoc(doc(db, 'companies', SCHOOL_CODE, 'active_buses', d.id)))
                );
                toast.success('Mapa limpiado correctamente');
              }}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-[11px] font-black uppercase tracking-wide bg-slate-800 text-slate-300 hover:text-white border border-slate-700 transition-colors"
            >
              <span className="material-symbols-outlined text-base">refresh</span>
              Mantenimiento
            </button>
          )}
        </div>
      </div>

      {/* ── Mapa + panel flotante Rutas en vivo ── */}
      <div className="relative">
        <LiveMap
          buses={liveBuses}
          students={students}
          showStudents={showStudents}
          routeByDriver={routeByDriver}
          schoolCenter={{ lat: schoolInfo?.lat, lng: schoolInfo?.lng }}
          schoolName={schoolInfo?.name}
          schoolAddress={schoolInfo?.address}
          mapHeight="min(68vh, 620px)"
        />
        <LiveRoutesPanel rows={liveRouteRows} />
      </div>

      {/* ── Pie: estado + política ── */}
      <div className="mt-5 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-500">
        <div className="flex items-center gap-3">
          <span
            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold ${
              liveBuses.length > 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'
            }`}
          >
            {liveBuses.length > 0 && (
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            )}
            {liveBuses.length > 0
              ? `GPS activo — ${liveBuses.length} unidad(es) conectada(s)`
              : 'Esperando conexión de conductores'}
          </span>
          {openIncidents.length > 0 && (
            <span className="text-amber-700 font-bold bg-amber-50 px-2.5 py-1 rounded-full">
              {openIncidents.length} incidente(s) abierto(s)
            </span>
          )}
        </div>
        <p>
          Ubicación y rastreo según{' '}
          <Link href="/politica-seguridad" className="text-[#4361ee] font-bold hover:underline">
            política de seguridad
          </Link>
        </p>
      </div>
    </DashboardLayout>
  );
};

export default DashboardPage;
