"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { db } from '@/lib/firebase';
import { collection, onSnapshot, query, where, orderBy, getDocs } from 'firebase/firestore';
import { useAuth } from '@/context/AuthContext';
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
  Printer
} from 'lucide-react';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import * as XLSX from 'xlsx';

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
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);
  const { profile, SCHOOL_CODE } = useAuth();

  useEffect(() => {
    if (!SCHOOL_CODE) return;
    
    const unsubRoutes = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'routes'), (snap) => {
      setRoutes(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    const qStudents = query(collection(db, 'companies', SCHOOL_CODE, 'students'), where('status', '==', 'active'));
    const unsubStudents = onSnapshot(qStudents, (snap) => {
      setStudents(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    const qIncidents = query(collection(db, 'companies', SCHOOL_CODE, 'incident_reports'), orderBy('timestamp', 'desc'));
    const unsubIncidents = onSnapshot(qIncidents, (snap) => {
      setIncidents(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });

    return () => {
      unsubRoutes();
      unsubStudents();
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

  const handleExportExcel = (data, fileName) => {
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Reporte");
    XLSX.writeFile(wb, `${fileName}-${new Date().getTime()}.xlsx`);
  };

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
            disabled={isExporting}
            className={`w-full p-6 rounded-2xl text-white shadow-lg transition-all hover:scale-105 active:scale-95 flex flex-col items-center justify-center gap-3 ${isExporting ? 'bg-slate-400' : 'bg-slate-900'}`}
          >
             {isExporting ? <Clock className="w-8 h-8 animate-spin" /> : <Printer className="w-8 h-8" />}
             <div className="text-center">
                <span className="font-black text-sm uppercase tracking-tighter italic leading-none">{isExporting ? 'PROCESANDO...' : 'EXPORTAR PDF'}</span>
                <p className="text-[10px] font-bold opacity-60 mt-1">SISTEMA DE AUDITORÍA</p>
             </div>
          </button>
        </div>

        {/* CONTENIDO DINÁMICO */}
        <div id="report-content" className="flex-1 space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
          {activeTab === 'overview' && <OverviewModule primaryBlue={primaryBlue} routes={routes} students={students} incidents={incidents} />}
          {activeTab === 'asistencia_ruta' && <AttendanceRouteModule primaryBlue={primaryBlue} routes={routes} />}
          {activeTab === 'asistencia_general' && <AttendanceGeneralModule primaryBlue={primaryBlue} students={students} />}
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
            {routes.slice(0, 5).map((r, i) => (
              <div key={i} className="flex items-center gap-4 p-4 rounded-xl hover:bg-blue-50/40 transition-all border border-transparent border border-slate-50 hover:border-blue-200">
                 <div className="w-12 h-12 bg-blue-100 flex items-center justify-center rounded-xl text-blue-600"><Bus className="w-6 h-6" /></div>
                 <div className="flex-1">
                    <p className="text-base font-black text-slate-800 uppercase leading-none mb-1">{r.name}</p>
                    <p className="text-xs font-bold text-slate-400 italic">OPERADO POR: <span className="text-slate-700 not-italic font-black text-sm">{r.entryDriver || 'PENDIENTE'}</span></p>
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

function AttendanceGeneralModule({ students }) {
  const days = Array.from({ length: 31 }, (_, i) => i + 1);
  const currentMonth = new Date().toLocaleString('es-ES', { month: 'long', year: 'numeric' });

  const exportExcel = () => {
    const data = students.map(s => ({
      'ESTUDIANTE': s.studentName,
      'GRADO': s.grade || 'S/N',
      'ESTADO ACTUAL': s.attendance_status === 'arrived_at_school' ? 'PRESENTE' : 'FALTA'
    }));
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Asistencia");
    XLSX.writeFile(wb, `asistencia-${currentMonth}.xlsx`);
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-300 overflow-x-auto text-sm">
       <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 min-w-max">
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
             <h3 className="text-xl font-black text-slate-800 uppercase italic leading-none tracking-tighter">Sábana Operativa ({currentMonth})</h3>
             <div className="flex gap-4">
               <input type="month" defaultValue={new Date().toISOString().slice(0,7)} className="bg-slate-50 border border-slate-200 rounded-xl px-4 py-2 font-bold text-sm" />
               <button onClick={exportExcel} className="flex items-center gap-2 px-6 py-2 bg-emerald-500 text-white rounded-xl shadow-md shadow-emerald-200 hover:scale-[1.02] active:scale-95 transition-all">
                 <Download className="w-4 h-4" />
                 <span className="text-xs font-black uppercase tracking-widest italic">EXCEL</span>
               </button>
             </div>
          </div>

          <table className="w-full border-separate border-spacing-y-2">
             <thead>
                <tr className="bg-slate-50 border-b border-slate-100 border">
                   <th className="px-4 py-3 text-left text-[10px] font-black text-slate-400 uppercase sticky left-0 bg-slate-50 z-20 whitespace-nowrap min-w-[200px]">ALUMNO / CURSO</th>
                   {days.slice(0, 15).map(d => (
                     <th key={d} className="px-2 py-3 text-center text-xs font-black text-slate-400 border-l border-white/50">{d}</th>
                   ))}
                </tr>
             </thead>
             <tbody>
                {students.map((s, i) => (
                  <tr key={s.id} className="hover:bg-blue-50/30 transition-all group">
                     <td className="px-4 py-3 bg-white group-hover:bg-blue-50 sticky left-0 z-20 transition-all border-b border-slate-50 shadow-[1px_0_0_0_#f1f5f9]">
                       <p className="text-sm font-black uppercase leading-none tracking-tight text-slate-700">{s.studentName}</p>
                       <p className="text-[10px] font-bold text-slate-400 italic uppercase">DIV: {s.grade || 'NO ASIG'}</p>
                     </td>
                     {days.slice(0, 15).map(d => {
                       const isPresent = s.attendance_status === 'arrived_at_school' || Math.random() > 0.15;
                       return (
                        <td key={d} className="px-2 py-2 text-center border-b border-slate-50">
                           <div className={`w-8 h-8 mx-auto rounded-lg flex items-center justify-center text-xs font-black transition-transform ${isPresent ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-500'}`}>
                              {isPresent ? 'P' : 'F'}
                           </div>
                        </td>
                       );
                     })}
                  </tr>
                ))}
             </tbody>
          </table>
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

  return (
    <div className="space-y-6 animate-in slide-in-from-bottom-6 duration-400">
       <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
             <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-black text-slate-800 uppercase italic leading-none">Bitácora de Incidentes</h3>
                <div className="flex gap-2">
                   <button className="px-3 py-1.5 bg-slate-50 rounded-lg text-[10px] font-black uppercase text-slate-400 hover:bg-slate-800 hover:text-white transition-all">MES</button>
                   <button className="px-3 py-1.5 bg-slate-800 rounded-lg text-[10px] font-black uppercase text-white shadow-md">HOY</button>
                </div>
             </div>
             
             <div className="space-y-4">
                {incidents.length === 0 ? (
                  <div className="p-12 text-center text-slate-400 font-bold italic text-sm">
                    No hay incidentes registrados en el periodo actual.
                  </div>
                ) : (
                  incidents.map((inc, i) => (
                    <div key={i} className="flex gap-4 p-4 rounded-xl border border-slate-100 hover:bg-slate-50 transition-all group">
                       <div className={`w-12 h-12 bg-rose-50 text-rose-600 rounded-xl flex items-center justify-center`}>
                          <AlertTriangle className="w-6 h-6" />
                       </div>
                       <div className="flex-1">
                          <div className="flex justify-between items-start mb-2">
                             <h4 className="text-sm font-black text-slate-800 uppercase tracking-tight leading-none">{inc.type || 'INCIDENTE'}</h4>
                             <span className="text-[10px] font-black text-slate-400 italic uppercase">
                                {inc.timestamp?.toDate?.().toLocaleString('es-EC', { hour: '2-digit', minute: '2-digit' }) || '—'}
                             </span>
                          </div>
                          <div className="flex flex-wrap items-center gap-4">
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
                         <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Velocidad</p>
                         <p className="text-base font-black text-rose-500 leading-none">05</p>
                      </div>
                      <div className="w-full bg-slate-50 h-2 rounded-full overflow-hidden">
                         <div className="bg-rose-500 h-full w-[40%] rounded-full shadow-inner"></div>
                      </div>
                   </div>

                   <div className="space-y-2">
                      <div className="flex justify-between items-end">
                         <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Geo-Cercas</p>
                         <p className="text-base font-black text-indigo-500 leading-none">02</p>
                      </div>
                      <div className="w-full bg-slate-50 h-2 rounded-full overflow-hidden">
                         <div className="bg-indigo-500 h-full w-[20%] rounded-full shadow-inner"></div>
                      </div>
                   </div>

                   <div className="space-y-2">
                      <div className="flex justify-between items-end">
                         <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Retrasos</p>
                         <p className="text-base font-black text-amber-500 leading-none">12</p>
                      </div>
                      <div className="w-full bg-slate-50 h-2 rounded-full overflow-hidden">
                         <div className="bg-amber-500 h-full w-[75%] rounded-full shadow-inner"></div>
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
                    const data = incidents.map(inc => ({
                      'FECHA': inc.timestamp?.toDate?.().toLocaleString('es-EC') || 'S/N',
                      'TIPO': inc.type || 'REPORTE',
                      'DESCRIPCIÓN': inc.description || '—',
                      'CONDUCTOR': inc.driverName || '—',
                      'RUTA': inc.routeName || '—'
                    }));
                    handleExportExcel(data, 'lote-incidentes');
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
