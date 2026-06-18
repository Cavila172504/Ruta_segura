"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { db } from '@/lib/firebase';
import { collection, onSnapshot, query, where, orderBy, getDocs } from 'firebase/firestore';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { 
  BarChart3, 
  Users, 
  Map, 
  AlertTriangle, 
  Calendar, 
  Download, 
  Search, 
  ChevronRight, 
  PieChart, 
  FileText,
  Clock,
  TrendingUp,
  Filter,
  ArrowRight,
  UserCheck,
  UserX,
  Bus,
  Printer,
  ArrowLeft
} from 'lucide-react';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import { exportToXls, mergeDriverOptions, driverDisplayName } from '@/lib/export-excel';

const ReportTabs = [
  { id: 'overview', label: 'Resumen Operativo', icon: BarChart3, desc: 'Vista global del sistema' },
  { id: 'asistencia_ruta', label: 'Asistencia por Ruta', icon: Map, desc: 'Detalle por recorrido' },
  { id: 'asistencia_general', label: 'Asistencia General', icon: Users, desc: 'Sábana de asistencia mensual' },
  { id: 'consulta_ruta', label: 'Consulta por Ruta', icon: Bus, desc: 'Información de flota' },
  { id: 'novedades', label: 'Novedades', icon: AlertTriangle, desc: 'Incidentes y alertas' },
];

export default function ReportsPage() {
  const [activeTab, setActiveTab] = useState('overview');
  const [routes, setRoutes] = useState([]);
  const [students, setStudents] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [authDrivers, setAuthDrivers] = useState([]);
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);
  const [isExportingExcel, setIsExportingExcel] = useState(false);
  const { profile, SCHOOL_CODE } = useAuth();
  const toast = useToast();

  useEffect(() => {
    if (!SCHOOL_CODE) return;
    const unitCode = String(SCHOOL_CODE).trim().toUpperCase();
    
    const unsubRoutes = onSnapshot(collection(db, 'companies', unitCode, 'routes'), (snap) => {
      setRoutes(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    const qStudents = query(collection(db, 'companies', unitCode, 'students'), where('status', '==', 'active'));
    const unsubStudents = onSnapshot(qStudents, (snap) => {
      setStudents(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    const unsubDrivers = onSnapshot(collection(db, 'companies', unitCode, 'drivers'), (snap) => {
      setDrivers(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    }, (err) => console.error('Error cargando conductores:', err));

    const qAuthDrivers = query(
      collection(db, 'users', 'drivers', 'members'),
      where('unitCode', '==', unitCode)
    );
    const unsubAuthDrivers = onSnapshot(qAuthDrivers, (snap) => {
      setAuthDrivers(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    }, (err) => console.error('Error cargando conductores (auth):', err));

    const qIncidents = query(collection(db, 'companies', unitCode, 'incident_reports'), orderBy('timestamp', 'desc'));
    const unsubIncidents = onSnapshot(qIncidents, (snap) => {
      setIncidents(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });

    return () => {
      unsubRoutes();
      unsubStudents();
      unsubDrivers();
      unsubAuthDrivers();
      unsubIncidents();
    };
  }, [SCHOOL_CODE]);

  const handleExportPDF = async () => {
    const input = document.getElementById('report-content');
    if (!input) return;
    
    setIsExporting(true);
    try {
      const canvas = await html2canvas(input, {
        scale: 2,
        useCORS: true,
        logging: false,
        backgroundColor: '#F8FAFC'
      });
      const imgData = canvas.toDataURL('image/png');
      const pdf = new jsPDF('p', 'mm', 'a4');
      const imgProps = pdf.getImageProperties(imgData);
      const pdfWidth = pdf.internal.pageSize.getWidth();
      const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;
      
      pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
      pdf.save(`informe-rutasegura-${activeTab}-${new Date().getTime()}.pdf`);
    } catch (error) {
      console.error('Error exportando PDF:', error);
    } finally {
      setIsExporting(false);
    }
  };

  const handleExportExcel = (data, fileName, sheetName = 'Reporte') => {
    exportToXls(data, `${fileName}-${new Date().getTime()}`, sheetName);
  };

  const buildTabExcelData = () => {
    const today = new Date().toDateString();
    const incidentsToday = incidents.filter((i) => i.timestamp?.toDate?.().toDateString() === today);

    switch (activeTab) {
      case 'overview':
        return {
          sheetName: 'Resumen',
          fileName: `resumen-operativo-${unitCode}`,
          rows: [
            { SECCIÓN: 'MÉTRICAS', DETALLE: '', VALOR: '' },
            { SECCIÓN: 'Alumnos activos', DETALLE: '', VALOR: students.length },
            { SECCIÓN: 'Rutas registradas', DETALLE: '', VALOR: routes.length },
            { SECCIÓN: 'Conductores', DETALLE: '', VALOR: driverOptions.length },
            { SECCIÓN: 'Incidentes hoy', DETALLE: '', VALOR: incidentsToday.length },
            { SECCIÓN: '', DETALLE: '', VALOR: '' },
            { SECCIÓN: 'RUTAS', DETALLE: 'Conductor', VALOR: 'Estudiantes' },
            ...routes.map((r) => ({
              SECCIÓN: r.name || 'Sin nombre',
              DETALLE: r.entryDriver || 'Sin conductor',
              VALOR: r.assignedStudents?.length || 0,
            })),
          ],
        };
      case 'asistencia_ruta':
        return {
          sheetName: 'AsistenciaRuta',
          fileName: `asistencia-por-ruta-${unitCode}`,
          rows: routes.map((r) => ({
            RUTA: r.name || '—',
            CONDUCTOR: r.entryDriver || '—',
            TURNO: r.shift || '—',
            ESTUDIANTES: r.assignedStudents?.length || 0,
            ESTADO: r.status || '—',
          })),
        };
      case 'asistencia_general':
        return {
          sheetName: 'Asistencia',
          fileName: `asistencia-general-${unitCode}`,
          rows: students.map((s) => {
            const driver = driverOptions.find((d) => d.id === s.driverId);
            const status = s.attendance_status;
            let asistencia = 'Sin registro';
            if (['absent_today', 'absent'].includes(status)) asistencia = 'F';
            else if (['arrived_at_school', 'in_bus', 'dropped_off_at_home', 'present'].includes(status)) asistencia = 'P';
            return {
              CONDUCTOR: driver ? driverDisplayName(driver) : '—',
              ESTUDIANTE: s.studentName || '—',
              GRADO: s.grade || '—',
              RUTA: s.assignedRoute || '—',
              ASISTENCIA_HOY: asistencia,
            };
          }),
        };
      case 'consulta_ruta':
        return {
          sheetName: 'Flota',
          fileName: `consulta-rutas-${unitCode}`,
          rows: routes.map((r) => ({
            RUTA: r.name || '—',
            ID: r.id?.slice(-6)?.toUpperCase() || '—',
            CONDUCTOR: r.entryDriver || '—',
            CAPACIDAD: r.assignedStudents?.length || 0,
            UNIDAD: r.entryUnit || '—',
            TURNO: r.shift || '—',
          })),
        };
      case 'novedades':
        return {
          sheetName: 'Novedades',
          fileName: `novedades-${unitCode}`,
          rows: incidents.map((inc) => ({
            FECHA: inc.timestamp?.toDate?.().toLocaleString('es-EC') || '—',
            TIPO: inc.type || '—',
            CATEGORÍA: inc.category || '—',
            DESCRIPCIÓN: inc.description || '—',
            VELOCIDAD: inc.speed != null ? `${Math.round(inc.speed)} km/h` : '—',
            RETRASO_MIN: inc.delayMinutes ?? '—',
            CONDUCTOR: inc.driverName || '—',
            RUTA: inc.routeName || '—',
          })),
        };
      default:
        return { sheetName: 'Reporte', fileName: `informe-${unitCode}`, rows: [] };
    }
  };

  const handleExportTabExcel = () => {
    const { rows, fileName, sheetName } = buildTabExcelData();
    if (!rows.length) {
      toast.info('No hay datos para exportar en esta sección.');
      return;
    }
    setIsExportingExcel(true);
    try {
      handleExportExcel(rows, fileName, sheetName);
    } finally {
      setIsExportingExcel(false);
    }
  };

  const unitCode = SCHOOL_CODE ? String(SCHOOL_CODE).trim().toUpperCase() : '';
  const driverOptions = mergeDriverOptions(
    [...drivers, ...authDrivers.map((d) => ({ ...d, names: d.name?.split(' ')[0], lastNames: d.name?.split(' ').slice(1).join(' ') }))],
    routes,
    students
  );

  const primaryBlue = 'bg-[#4361ee]';
  const primaryBlueText = 'text-[#4361ee]';

  return (
    <DashboardLayout title="Centro de Informes Inteligente">
      <div className="flex flex-col lg:flex-row gap-8 min-h-[calc(100vh-200px)]">
        
        {/* SIDEBAR DE INFORMES */}
        <div className="w-full lg:w-72 flex flex-col gap-4">
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 h-fit">
            <h2 className="text-lg font-black text-slate-800 mb-6 px-2 tracking-tight">INFORMES</h2>
            <div className="space-y-2">
              {ReportTabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center gap-4 px-4 py-3 rounded-xl transition-all text-left group ${
                      isActive 
                        ? `${primaryBlue} text-white shadow-md shadow-blue-200 scale-[1.02]` 
                        : 'bg-white text-slate-500 hover:bg-slate-50 hover:text-slate-800'
                    }`}
                  >
                    <div className={`p-2.5 rounded-lg ${isActive ? 'bg-white/20' : 'bg-slate-50 group-hover:bg-white'}`}>
                      <Icon className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-black uppercase tracking-tight leading-none mb-1">{tab.label}</p>
                      <p className={`text-[10px] font-bold opacity-70 italic ${isActive ? 'text-white' : 'text-slate-400'}`}>{tab.desc}</p>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          <button 
            onClick={handleExportPDF}
            disabled={isExporting || isExportingExcel}
            className={`w-full p-5 rounded-2xl text-white shadow-lg transition-all hover:scale-105 active:scale-95 flex flex-col items-center justify-center gap-2 ${isExporting ? 'bg-slate-400' : 'bg-slate-900'}`}
          >
             {isExporting ? <Clock className="w-7 h-7 animate-spin" /> : <Printer className="w-7 h-7" />}
             <div className="text-center">
                <span className="font-black text-xs uppercase tracking-tighter italic leading-none">{isExporting ? 'PROCESANDO...' : 'EXPORTAR PDF'}</span>
                <p className="text-[10px] font-bold opacity-60 mt-1">Vista en pantalla</p>
             </div>
          </button>

          <button
            type="button"
            onClick={handleExportTabExcel}
            disabled={isExporting || isExportingExcel}
            className={`w-full p-5 rounded-2xl text-white shadow-lg transition-all hover:scale-105 active:scale-95 flex flex-col items-center justify-center gap-2 ${
              isExportingExcel ? 'bg-slate-400' : 'bg-emerald-600 hover:bg-emerald-500'
            }`}
          >
            {isExportingExcel ? (
              <Clock className="w-7 h-7 animate-spin" />
            ) : (
              <Download className="w-7 h-7" />
            )}
            <div className="text-center">
              <span className="font-black text-xs uppercase tracking-tighter italic leading-none">
                {isExportingExcel ? 'PROCESANDO...' : 'EXPORTAR EXCEL'}
              </span>
              <p className="text-[10px] font-bold opacity-80 mt-1">Archivo .xls — pestaña actual</p>
            </div>
          </button>
        </div>

        {/* CONTENIDO DINÁMICO */}
        <div id="report-content" className="flex-1 space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
          {activeTab === 'overview' && <OverviewModule primaryBlue={primaryBlue} routes={routes} students={students} incidents={incidents} />}
          {activeTab === 'asistencia_ruta' && <AttendanceRouteModule primaryBlue={primaryBlue} routes={routes} />}
          {activeTab === 'asistencia_general' && (
            <AttendanceGeneralModule
              students={students}
              driverOptions={driverOptions}
              unitCode={unitCode}
              handleExportExcel={handleExportExcel}
            />
          )}
          {activeTab === 'consulta_ruta' && <RouteQueryModule primaryBlue={primaryBlue} routes={routes} />}
          {activeTab === 'novedades' && <IncidentsModule primaryBlue={primaryBlue} incidents={incidents} handleExportExcel={handleExportExcel} />}
        </div>
      </div>
    </DashboardLayout>
  );
}

// --------------------------------------------------------------------------------
// MÓDULOS DE REPORTES (CON LETRA MÁS GRANDE)
// --------------------------------------------------------------------------------

function OverviewModule({ primaryBlue, routes, students, incidents }) {
  const stats = [
    { label: 'VIAJES TOTALES', value: routes.length * 2, change: '+12%', icon: Bus, color: 'emerald' },
    { label: 'ALUMNOS ACTIVOS', value: students.length, change: '+5%', icon: UserCheck, color: 'blue' },
    { label: 'INCIDENTES HOY', value: incidents.filter(i => {
      const today = new Date().toDateString();
      const incDate = i.timestamp?.toDate?.().toDateString();
      return incDate === today;
    }).length, change: '0%', icon: AlertTriangle, color: 'rose' },
  ];

  const displayRoutes = routes.filter(
    (r) => (r.name && String(r.name).trim()) || r.driverId || (r.assignedStudents?.length > 0)
  );

  return (
    <div className="space-y-6">
      {/* Metrics Banner */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {stats.map((s, i) => (
          <div key={i} className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm relative overflow-hidden group">
            <div className={`absolute -right-4 -bottom-4 opacity-10 group-hover:scale-110 transition-transform duration-500`}><s.icon className="w-24 h-24" /></div>
            <p className="text-xs font-black text-slate-400 uppercase tracking-widest italic mb-4">{s.label}</p>
            <div className="flex items-end justify-between relative z-10">
               <h4 className="text-4xl font-black text-slate-800 tracking-tighter">{s.value}</h4>
               <span className={`px-3 py-1 rounded-full text-[10px] font-black ${s.change.startsWith('+') ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>{s.change}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-slate-100">
         <div className="flex justify-between items-center mb-6 gap-4">
            <h3 className="text-xl font-black text-slate-800 uppercase italic leading-none">Actividad de Rutas (24h)</h3>
            <div className="flex items-center gap-2">
               <div className="w-3 h-3 bg-emerald-500 rounded-full animate-pulse"></div>
               <span className="text-[10px] font-black text-emerald-500 uppercase tracking-widest hidden sm:block">Sincronizado</span>
            </div>
         </div>
         <div className="space-y-3">
            {displayRoutes.length === 0 ? (
              <p className="text-sm text-slate-400 font-bold italic py-4">No hay rutas activas configuradas.</p>
            ) : displayRoutes.slice(0, 5).map((r) => (
              <div key={r.id} className="flex items-center gap-4 p-4 rounded-xl hover:bg-blue-50/40 transition-all border border-slate-50 hover:border-blue-200">
                 <div className="w-12 h-12 bg-blue-100 flex items-center justify-center rounded-xl text-blue-600"><Bus className="w-6 h-6" /></div>
                 <div className="flex-1">
                    <p className="text-base font-black text-slate-800 uppercase leading-none mb-1">{r.name || 'Ruta sin nombre'}</p>
                    <p className="text-xs font-bold text-slate-400 italic">
                      OPERADO POR:{' '}
                      <span className={`not-italic font-black text-sm ${r.entryDriver || r.driverId ? 'text-slate-700' : 'text-amber-600'}`}>
                        {r.entryDriver || (r.driverId ? 'Conductor asignado' : 'Sin conductor — asigne uno en Rutas')}
                      </span>
                    </p>
                 </div>
                 <div className="text-right hidden md:block px-6 border-r border-slate-100 mr-2">
                    <p className="text-[10px] font-black text-emerald-500 uppercase mb-0.5">En Ruta</p>
                    <p className="text-[10px] font-bold text-slate-400 italic uppercase">{r.assignedStudents?.length || 0} ESTUDIANTES</p>
                 </div>
                 <ChevronRight className="w-5 h-5 text-slate-300" />
              </div>
            ))}
         </div>
      </div>
    </div>
  );
}

function AttendanceRouteModule({ primaryBlue, routes }) {
  const [selectedRoute, setSelectedRoute] = useState('');
  
  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-6 duration-400">
       <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
          <h3 className="text-xl font-black text-slate-800 uppercase italic mb-6">Buscador Detallado de Asistencia</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 items-end">
             <div className="space-y-2">
                <label className="text-[10px] font-black text-slate-400 uppercase italic block tracking-widest">Recorrido Específico</label>
                <select className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-2 outline-none font-bold text-sm text-slate-700" onChange={(e) => setSelectedRoute(e.target.value)}>
                   <option value="">TODAS LAS RUTAS</option>
                   {routes.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
                </select>
             </div>
             <div className="space-y-2">
                <label className="text-[10px] font-black text-slate-400 uppercase italic block tracking-widest">Momento del Día</label>
                <select className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-2 outline-none font-bold text-sm text-slate-700">
                   <option>MAÑANA (ENTRADA)</option><option>TARDE (SALIDA)</option>
                </select>
             </div>
             <div className="space-y-2">
                <label className="text-[10px] font-black text-slate-400 uppercase italic block tracking-widest">Periodo</label>
                <input type="month" className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-2 outline-none font-bold text-sm text-slate-700 uppercase" />
             </div>
             <button className={`w-full py-2 ${primaryBlue} text-white font-black rounded-xl shadow-md shadow-blue-200 hover:scale-102 transition-all uppercase text-xs italic tracking-widest`}>FILTRAR DATOS</button>
          </div>
       </div>

       <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-100">
          <div className="border-4 border-dashed border-slate-100 rounded-2xl p-12 flex flex-col items-center justify-center text-center">
             <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-6"><Filter className="w-8 h-8 text-slate-300" /></div>
             <p className="text-sm font-black text-slate-400 uppercase italic tracking-widest max-w-sm leading-relaxed">Configura los filtros superiores para proyectar el reporte de asistencia</p>
          </div>
       </div>
    </div>
  );
}

function AttendanceGeneralModule({ students, driverOptions, unitCode, handleExportExcel }) {
  const [selectedDriverId, setSelectedDriverId] = useState('');
  const [selectedMonth, setSelectedMonth] = useState(new Date().toISOString().slice(0, 7));
  const [driverSearch, setDriverSearch] = useState('');
  const [logsByStudent, setLogsByStudent] = useState({});

  const [year, month] = selectedMonth.split('-').map(Number);
  const daysInMonth = new Date(year, month, 0).getDate();
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);
  const monthLabel = new Date(year, month - 1, 1).toLocaleString('es-ES', { month: 'long', year: 'numeric' });

  const todayKey = (() => {
    const t = new Date();
    return `${t.getFullYear()}-${String(t.getMonth() + 1).padStart(2, '0')}-${String(t.getDate()).padStart(2, '0')}`;
  })();
  const todayDay = todayKey.startsWith(selectedMonth) ? parseInt(todayKey.split('-')[2], 10) : null;

  useEffect(() => {
    if (!unitCode || !selectedDriverId || !selectedMonth) {
      setLogsByStudent({});
      return;
    }

    const start = `${selectedMonth}-01`;
    const end = `${selectedMonth}-${String(daysInMonth).padStart(2, '0')}`;

    const q = query(
      collection(db, 'companies', unitCode, 'attendance_logs'),
      where('driverId', '==', selectedDriverId),
      where('date', '>=', start),
      where('date', '<=', end)
    );

    const unsub = onSnapshot(q, (snap) => {
      const map = {};
      snap.docs.forEach((docSnap) => {
        const data = docSnap.data();
        const dayNum = parseInt(data.date?.split('-')[2], 10);
        if (!map[data.studentId]) map[data.studentId] = {};
        map[data.studentId][dayNum] = data.reportCode;
      });
      setLogsByStudent(map);
    }, () => setLogsByStudent({}));

    return () => unsub();
  }, [unitCode, selectedDriverId, selectedMonth, daysInMonth]);

  const driverStudents = selectedDriverId
    ? students.filter((s) => s.driverId === selectedDriverId)
    : [];

  const selectedDriver = driverOptions.find((d) => d.id === selectedDriverId);

  const studentCountByDriver = (driverId) =>
    students.filter((s) => s.driverId === driverId).length;

  const filteredDrivers = driverOptions.filter((d) => {
    const q = driverSearch.trim().toLowerCase();
    if (!q) return true;
    const label = `${driverDisplayName(d)} ${d.idNumber || ''}`.toLowerCase();
    return label.includes(q);
  });

  const statusToCode = (status) => {
    if (['absent_today', 'absent'].includes(status)) return 'F';
    if (['arrived_at_school', 'in_bus', 'dropped_off_at_home', 'present'].includes(status)) return 'P';
    return null;
  };

  const getCellCode = (student, day) => {
    if (logsByStudent[student.id]?.[day]) return logsByStudent[student.id][day];
    const cellDate = `${selectedMonth}-${String(day).padStart(2, '0')}`;
    if (cellDate === todayKey && student.attendance_status) {
      return statusToCode(student.attendance_status);
    }
    return null;
  };

  const isWeekend = (day) => {
    const wd = new Date(year, month - 1, day).getDay();
    return wd === 0 || wd === 6;
  };

  const monthStats = driverStudents.reduce(
    (acc, s) => {
      days.forEach((d) => {
        const c = getCellCode(s, d);
        if (c === 'P') acc.present += 1;
        else if (c === 'F') acc.absent += 1;
        else acc.empty += 1;
      });
      return acc;
    },
    { present: 0, absent: 0, empty: 0 }
  );

  const exportExcel = () => {
    const data = driverStudents.map((s) => {
      const row = {
        CONDUCTOR: selectedDriver ? driverDisplayName(selectedDriver) : '—',
        ESTUDIANTE: s.studentName,
        GRADO: s.grade || 'S/N',
      };
      let p = 0;
      let f = 0;
      days.forEach((d) => {
        const code = getCellCode(s, d) || '—';
        row[`DÍA ${d}`] = code;
        if (code === 'P') p += 1;
        if (code === 'F') f += 1;
      });
      row['TOTAL P'] = p;
      row['TOTAL F'] = f;
      return row;
    });
    handleExportExcel(data, `asistencia-${selectedMonth}-${selectedDriverId}`, 'Asistencia');
  };

  const handlePickDriver = (id) => {
    setSelectedDriverId(id);
    setDriverSearch('');
  };

  const handleBackToPicker = () => {
    setSelectedDriverId('');
  };

  /* ── Paso 1: elegir conductor ── */
  if (!selectedDriverId) {
    return (
      <div className="space-y-6 animate-in fade-in duration-300">
        <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-slate-100">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-8">
            <div>
              <h3 className="text-xl font-black text-slate-800 uppercase italic tracking-tighter leading-none mb-2">
                Asistencia General
              </h3>
              <p className="text-sm text-slate-500 font-medium">
                Elija un conductor para ver la sábana mensual de sus estudiantes.
              </p>
            </div>
            <div className="space-y-2 w-full md:w-56">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest flex items-center gap-1">
                <Calendar className="w-3 h-3" /> Mes del reporte
              </label>
              <input
                type="month"
                value={selectedMonth}
                onChange={(e) => setSelectedMonth(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 font-bold text-sm"
              />
            </div>
          </div>

          {driverOptions.length > 3 && (
            <div className="relative mb-6 max-w-md">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Buscar conductor..."
                value={driverSearch}
                onChange={(e) => setDriverSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium outline-none focus:border-[#4361ee]"
              />
            </div>
          )}

          {driverOptions.length === 0 ? (
            <div className="text-center py-16 px-6 rounded-2xl border-2 border-dashed border-slate-200 bg-slate-50/50">
              <Bus className="w-14 h-14 text-slate-300 mx-auto mb-4" />
              <p className="text-sm font-black text-slate-500 uppercase italic mb-2">Sin conductores</p>
              <p className="text-xs text-slate-400 max-w-sm mx-auto">
                Registre conductores en el menú Conductores o asígnelos en Rutas.
              </p>
            </div>
          ) : filteredDrivers.length === 0 ? (
            <p className="text-center text-slate-400 py-12 font-bold italic">Ningún conductor coincide con la búsqueda.</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredDrivers.map((d) => {
                const count = studentCountByDriver(d.id);
                const initials = driverDisplayName(d)
                  .split(' ')
                  .filter(Boolean)
                  .slice(0, 2)
                  .map((w) => w[0])
                  .join('')
                  .toUpperCase();
                return (
                  <button
                    key={d.id}
                    type="button"
                    onClick={() => handlePickDriver(d.id)}
                    className="group text-left p-5 rounded-2xl border-2 border-slate-100 bg-white hover:border-[#4361ee] hover:shadow-lg hover:shadow-blue-100/80 transition-all duration-200"
                  >
                    <div className="flex items-start gap-4">
                      <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#4361ee] to-indigo-600 text-white flex items-center justify-center text-lg font-black shrink-0 group-hover:scale-105 transition-transform">
                        {initials || 'C'}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-black text-slate-800 uppercase leading-tight truncate">
                          {driverDisplayName(d)}
                        </p>
                        {d.idNumber && (
                          <p className="text-[10px] font-bold text-slate-400 mt-1">Cédula: {d.idNumber}</p>
                        )}
                        <p className="text-xs font-bold text-[#4361ee] mt-2 flex items-center gap-1">
                          <Users className="w-3.5 h-3.5" />
                          {count} estudiante{count !== 1 ? 's' : ''}
                        </p>
                      </div>
                      <ChevronRight className="w-5 h-5 text-slate-300 group-hover:text-[#4361ee] shrink-0 mt-1" />
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>
    );
  }

  /* ── Paso 2: sábana del conductor ── */
  return (
    <div className="space-y-6 animate-in slide-in-from-right-4 duration-300">
      <div className="bg-gradient-to-r from-[#4361ee] to-indigo-600 rounded-2xl p-6 text-white shadow-lg shadow-blue-200/40">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-start gap-4">
            <button
              type="button"
              onClick={handleBackToPicker}
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white/15 hover:bg-white/25 border border-white/20 text-white text-xs font-black uppercase tracking-widest transition-all shrink-0"
            >
              <ArrowLeft className="w-4 h-4" />
              Cambiar conductor
            </button>
            <div>
              <p className="text-[10px] font-black uppercase tracking-widest text-white/70 mb-1">Conductor seleccionado</p>
              <h3 className="text-xl font-black uppercase italic leading-tight">
                {driverDisplayName(selectedDriver)}
              </h3>
              {selectedDriver?.idNumber && (
                <p className="text-xs font-bold text-white/80 mt-1">ID: {selectedDriver.idNumber}</p>
              )}
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <input
              type="month"
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
              className="bg-white/15 border border-white/25 rounded-xl px-4 py-2 text-sm font-bold text-white [&::-webkit-calendar-picker-indicator]:invert"
            />
            <button
              type="button"
              onClick={exportExcel}
              disabled={driverStudents.length === 0}
              className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-400 text-white rounded-xl font-black text-xs uppercase tracking-widest disabled:opacity-40 transition-all"
            >
              <Download className="w-4 h-4" />
              Exportar .xls
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
          <p className="text-[10px] font-black text-slate-400 uppercase">Estudiantes</p>
          <p className="text-2xl font-black text-slate-800">{driverStudents.length}</p>
        </div>
        <div className="bg-white p-4 rounded-xl border border-emerald-100 shadow-sm">
          <p className="text-[10px] font-black text-emerald-600 uppercase">Presentes (mes)</p>
          <p className="text-2xl font-black text-emerald-600">{monthStats.present}</p>
        </div>
        <div className="bg-white p-4 rounded-xl border border-rose-100 shadow-sm">
          <p className="text-[10px] font-black text-rose-500 uppercase">Faltas (mes)</p>
          <p className="text-2xl font-black text-rose-500">{monthStats.absent}</p>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
          <p className="text-[10px] font-black text-slate-400 uppercase">Sin registro</p>
          <p className="text-2xl font-black text-slate-400">{monthStats.empty}</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <h4 className="text-base font-black text-slate-800 uppercase italic">
            Sábana — {monthLabel}
          </h4>
          <div className="flex flex-wrap gap-2 text-[10px] font-black uppercase">
            <span className="px-2.5 py-1 bg-emerald-50 text-emerald-600 rounded-lg border border-emerald-100">P Presente</span>
            <span className="px-2.5 py-1 bg-rose-50 text-rose-500 rounded-lg border border-rose-100">F Falta</span>
            <span className="px-2.5 py-1 bg-slate-50 text-slate-400 rounded-lg border border-slate-100">— Sin dato</span>
            {todayDay && (
              <span className="px-2.5 py-1 bg-blue-50 text-blue-600 rounded-lg border border-blue-200">Hoy resaltado</span>
            )}
          </div>
        </div>

        {driverStudents.length === 0 ? (
          <p className="text-center text-slate-400 py-16 font-bold italic">
            Este conductor no tiene estudiantes activos asignados.
          </p>
        ) : (
          <div className="overflow-auto max-h-[min(70vh,640px)]">
            <table className="w-full text-sm border-collapse min-w-max">
              <thead className="sticky top-0 z-30 bg-slate-100 shadow-sm">
                <tr>
                  <th className="px-4 py-3 text-left text-[10px] font-black text-slate-500 uppercase sticky left-0 bg-slate-100 z-40 min-w-[180px] border-r border-slate-200">
                    Alumno
                  </th>
                  {days.map((d) => (
                    <th
                      key={d}
                      className={`px-1 py-2 text-center text-[10px] font-black w-9 border-r border-slate-200/50 ${
                        d === todayDay
                          ? 'bg-blue-100 text-blue-700'
                          : isWeekend(d)
                            ? 'bg-slate-200/60 text-slate-500'
                            : 'text-slate-500'
                      }`}
                    >
                      {d}
                    </th>
                  ))}
                  <th className="px-2 py-2 text-center text-[10px] font-black text-emerald-600 bg-emerald-50/80 sticky right-8 z-40 min-w-[36px]">P</th>
                  <th className="px-2 py-2 text-center text-[10px] font-black text-rose-500 bg-rose-50/80 sticky right-0 z-40 min-w-[36px]">F</th>
                </tr>
              </thead>
              <tbody>
                {driverStudents.map((s, rowIdx) => {
                  let rowP = 0;
                  let rowF = 0;
                  return (
                    <tr
                      key={s.id}
                      className={rowIdx % 2 === 0 ? 'bg-white' : 'bg-slate-50/40'}
                    >
                      <td className="px-4 py-3 sticky left-0 z-20 bg-inherit border-r border-slate-100 shadow-[2px_0_4px_-2px_rgba(0,0,0,0.06)]">
                        <p className="text-sm font-black text-slate-800 uppercase leading-tight">{s.studentName}</p>
                        <p className="text-[10px] font-bold text-slate-400 uppercase">{s.grade || 'Sin curso'}</p>
                      </td>
                      {days.map((d) => {
                        const code = getCellCode(s, d);
                        if (code === 'P') rowP += 1;
                        if (code === 'F') rowF += 1;
                        const isToday = d === todayDay;
                        return (
                          <td
                            key={d}
                            className={`px-0.5 py-1.5 text-center border-r border-slate-100/80 ${
                              isToday ? 'bg-blue-50/80' : isWeekend(d) ? 'bg-slate-100/50' : ''
                            }`}
                          >
                            <div
                              className={`w-7 h-7 mx-auto rounded-md flex items-center justify-center text-[10px] font-black ${
                                code === 'P'
                                  ? 'bg-emerald-500 text-white shadow-sm'
                                  : code === 'F'
                                    ? 'bg-rose-500 text-white shadow-sm'
                                    : 'bg-slate-100 text-slate-300'
                              } ${isToday && code ? 'ring-2 ring-blue-400 ring-offset-1' : ''}`}
                            >
                              {code || '·'}
                            </div>
                          </td>
                        );
                      })}
                      <td className="px-2 py-2 text-center font-black text-emerald-600 bg-emerald-50/50 sticky right-8 z-10 text-xs">
                        {rowP}
                      </td>
                      <td className="px-2 py-2 text-center font-black text-rose-500 bg-rose-50/50 sticky right-0 z-10 text-xs">
                        {rowF}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function RouteQueryModule({ routes }) {
  const [searchTerm, setSearchTerm] = useState('');
  const filtered = routes.filter(r => r.name?.toLowerCase().includes(searchTerm.toLowerCase()));

  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-6 duration-400">
       <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-slate-100">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-8">
             <h3 className="text-xl font-black text-slate-800 uppercase italic">Análisis Frecuencia Operativa</h3>
             <div className="relative w-full md:w-80">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                <input 
                  placeholder="Buscar Ruta..."
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-100 rounded-xl pl-10 pr-4 py-2 outline-none font-bold text-sm text-slate-700"
                />
             </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
             {filtered.map(r => (
               <div key={r.id} className="bg-white p-6 rounded-2xl border border-slate-100 hover:shadow-lg hover:border-blue-200 transition-all group relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-20 h-20 bg-blue-50/50 rounded-bl-full -mr-8 -mt-8 group-hover:bg-blue-500 transition-all duration-500"></div>
                  <div className="flex items-center gap-4 relative z-10">
                     <div className="w-12 h-12 bg-slate-50 rounded-xl flex items-center justify-center group-hover:bg-white group-hover:text-blue-600 transition-all text-slate-400">
                        <Bus className="w-6 h-6" />
                     </div>
                     <div className="flex-1">
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest italic mb-0.5">ID: {r.id.slice(-4).toUpperCase()}</p>
                        <h4 className="text-base font-black text-slate-800 uppercase leading-none mb-1">{r.name}</h4>
                        <p className="text-xs font-bold text-slate-500 italic uppercase">COND: <span className="text-slate-800">{r.entryDriver || 'PENDIENTE'}</span></p>
                     </div>
                  </div>
                  <div className="grid grid-cols-3 gap-4 mt-6 pt-6 border-t border-slate-100 relative z-10">
                     <div className="text-center"><p className="text-[10px] font-black text-slate-400 uppercase italic mb-1">Capacidad</p><p className="text-sm font-black text-slate-800">{r.assignedStudents?.length || 0}</p></div>
                     <div className="text-center"><p className="text-[10px] font-black text-slate-400 uppercase italic mb-1">Puntualidad</p><p className="text-sm font-black text-emerald-500">98%</p></div>
                     <div className="text-center"><p className="text-[10px] font-black text-slate-400 uppercase italic mb-1">Rendimi.</p><p className="text-sm font-black text-blue-600">A+</p></div>
                  </div>
               </div>
             ))}
             {filtered.length === 0 && <p className="text-sm text-slate-400">No hay rutas coincidentes.</p>}
          </div>
       </div>
    </div>
  );
}

function IncidentsModule({ incidents, handleExportExcel }) {
  const [period, setPeriod] = useState('today');

  const filtered = incidents.filter((inc) => {
    const ts = inc.timestamp?.toDate?.();
    if (!ts) return period === 'month';
    if (period === 'today') {
      return ts.toDateString() === new Date().toDateString();
    }
    const now = new Date();
    return ts.getMonth() === now.getMonth() && ts.getFullYear() === now.getFullYear();
  });

  const countByCategory = (cat) =>
    filtered.filter((i) => (i.category || '').toLowerCase() === cat).length;

  const speedCount = countByCategory('velocidad');
  const geofenceCount = countByCategory('geo_cerca');
  const delayCount = countByCategory('retraso');
  const maxMetric = Math.max(speedCount, geofenceCount, delayCount, 1);

  const incidentIcon = (inc) => {
    const cat = (inc.category || '').toLowerCase();
    if (cat === 'velocidad') return 'speed';
    if (cat === 'retraso') return 'schedule';
    return 'warning';
  };

  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-6 duration-400">
       <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
             <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-black text-slate-800 uppercase italic leading-none">Bitácora de Incidentes</h3>
                <div className="flex gap-2">
                   <button
                     type="button"
                     onClick={() => setPeriod('month')}
                     className={`px-3 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all ${period === 'month' ? 'bg-slate-800 text-white shadow-md' : 'bg-slate-50 text-slate-400 hover:bg-slate-200'}`}
                   >
                     MES
                   </button>
                   <button
                     type="button"
                     onClick={() => setPeriod('today')}
                     className={`px-3 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all ${period === 'today' ? 'bg-slate-800 text-white shadow-md' : 'bg-slate-50 text-slate-400 hover:bg-slate-200'}`}
                   >
                     HOY
                   </button>
                </div>
             </div>
             
             <div className="space-y-4 max-h-[520px] overflow-y-auto pr-1">
                {filtered.length === 0 ? (
                  <div className="p-12 text-center text-slate-400 font-bold italic text-sm">
                    No hay incidentes registrados en el periodo actual.
                    <p className="text-[10px] mt-2 font-normal not-italic">
                      Se registran automáticamente: exceso de velocidad (&gt;80 km/h) y retrasos en llegada al colegio.
                    </p>
                  </div>
                ) : (
                  filtered.map((inc) => (
                    <div key={inc.id} className="flex gap-4 p-4 rounded-xl border border-slate-100 hover:bg-slate-50 transition-all group">
                       <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${
                         (inc.category || '') === 'velocidad' ? 'bg-rose-50 text-rose-600' :
                         (inc.category || '') === 'retraso' ? 'bg-amber-50 text-amber-600' :
                         'bg-indigo-50 text-indigo-600'
                       }`}>
                          <span className="material-symbols-outlined">{incidentIcon(inc)}</span>
                       </div>
                       <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-start mb-2 gap-2">
                             <h4 className="text-sm font-black text-slate-800 uppercase tracking-tight leading-none">{inc.type || 'INCIDENTE'}</h4>
                             <span className="text-[10px] font-black text-slate-400 italic uppercase shrink-0">
                                {inc.timestamp?.toDate?.().toLocaleString('es-EC', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) || '—'}
                             </span>
                          </div>
                          {inc.description && (
                            <p className="text-xs text-slate-600 mb-2 leading-relaxed">{inc.description}</p>
                          )}
                          <div className="flex flex-wrap items-center gap-4">
                             {inc.speed != null && (
                               <p className="text-[10px] font-bold text-rose-500 uppercase">
                                 {Math.round(inc.speed)} km/h
                               </p>
                             )}
                             {inc.delayMinutes != null && (
                               <p className="text-[10px] font-bold text-amber-600 uppercase">
                                 +{inc.delayMinutes} min retraso
                               </p>
                             )}
                             <p className="text-[10px] font-bold text-slate-500 uppercase flex items-center gap-1.5">
                                <Bus className="w-3.5 h-3.5 text-blue-400" /> <span className="text-slate-700">{inc.routeName || 'No asig.'}</span>
                             </p>
                             <p className="text-[10px] font-bold text-slate-500 uppercase flex items-center gap-1.5">
                                <Users className="w-3.5 h-3.5 text-blue-400" /> <span className="text-slate-800">{inc.driverName || 'No asig.'}</span>
                             </p>
                          </div>
                       </div>
                    </div>
                  ))
                )}
             </div>
          </div>

          <div className="space-y-6">
             <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
                <h4 className="text-sm font-black text-slate-800 uppercase italic mb-6">Métricas de Alerta</h4>
                <div className="space-y-5">
                   <div className="space-y-2">
                      <div className="flex justify-between items-end">
                         <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Velocidad (&gt;80 km/h)</p>
                         <p className="text-base font-black text-rose-500 leading-none">{String(speedCount).padStart(2, '0')}</p>
                      </div>
                      <div className="w-full bg-slate-50 h-2 rounded-full overflow-hidden">
                         <div className="bg-rose-500 h-full rounded-full shadow-inner" style={{ width: `${(speedCount / maxMetric) * 100}%` }} />
                      </div>
                   </div>

                   <div className="space-y-2">
                      <div className="flex justify-between items-end">
                         <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest" title="Alertas cuando la unidad sale de la zona permitida del recorrido">
                            Geo-cercas
                         </p>
                         <p className="text-base font-black text-indigo-500 leading-none">{String(geofenceCount).padStart(2, '0')}</p>
                      </div>
                      <p className="text-[9px] text-slate-400 italic">Salida de la zona permitida del recorrido</p>
                      <div className="w-full bg-slate-50 h-2 rounded-full overflow-hidden">
                         <div className="bg-indigo-500 h-full rounded-full shadow-inner" style={{ width: `${(geofenceCount / maxMetric) * 100}%` }} />
                      </div>
                   </div>

                   <div className="space-y-2">
                      <div className="flex justify-between items-end">
                         <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Retrasos</p>
                         <p className="text-base font-black text-amber-500 leading-none">{String(delayCount).padStart(2, '0')}</p>
                      </div>
                      <div className="w-full bg-slate-50 h-2 rounded-full overflow-hidden">
                         <div className="bg-amber-500 h-full rounded-full shadow-inner" style={{ width: `${(delayCount / maxMetric) * 100}%` }} />
                      </div>
                   </div>
                </div>
             </div>

             <div className="bg-slate-900 p-6 rounded-2xl text-white shadow-xl relative overflow-hidden group">
                <PieChart className="absolute -right-4 -bottom-4 w-24 h-24 opacity-10 group-hover:scale-110 transition-transform duration-700" />
                <h4 className="text-sm font-black uppercase italic mb-2 tracking-tighter">Archivo Mensual</h4>
                <p className="text-[10px] text-slate-400 mb-6 leading-relaxed italic z-10 relative">Exporta consolidado de novedades.</p>
                <button 
                  onClick={() => {
                    const data = filtered.map(inc => ({
                      'FECHA': inc.timestamp?.toDate?.().toLocaleString('es-EC') || 'S/N',
                      'TIPO': inc.type || 'REPORTE',
                      'CATEGORÍA': inc.category || '—',
                      'DESCRIPCIÓN': inc.description || '—',
                      'VELOCIDAD': inc.speed != null ? `${Math.round(inc.speed)} km/h` : '—',
                      'RETRASO MIN': inc.delayMinutes ?? '—',
                      'CONDUCTOR': inc.driverName || '—',
                      'RUTA': inc.routeName || '—'
                    }));
                    handleExportExcel(data, 'lote-incidentes', 'Novedades');
                  }}
                  className="w-full py-3 bg-blue-600 text-white font-black rounded-xl text-[10px] uppercase shadow-lg shadow-blue-500/20 hover:brightness-110 transition-all z-10 relative"
                >
                  DESCARGAR LOTE EXCEL
                </button>
             </div>
          </div>
       </div>
    </div>
  );
}
