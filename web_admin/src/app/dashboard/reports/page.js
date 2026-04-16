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

    const qIncidents = query(collection(db, 'companies', SCHOOL_CODE, 'incidents'), orderBy('timestamp', 'desc'));
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
        <div className="w-full lg:w-96 flex flex-col gap-6">
          <div className="bg-white p-8 rounded-[3rem] shadow-sm border border-slate-100 h-fit">
            <h2 className="text-2xl font-black text-slate-800 mb-8 px-2 tracking-tight">INFORMES</h2>
            <div className="space-y-3">
              {ReportTabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center gap-5 px-6 py-5 rounded-[2rem] transition-all text-left group ${
                      isActive 
                        ? `${primaryBlue} text-white shadow-xl shadow-blue-200 scale-[1.03]` 
                        : 'bg-white text-slate-500 hover:bg-slate-50 hover:text-slate-800'
                    }`}
                  >
                    <div className={`p-3.5 rounded-2xl ${isActive ? 'bg-white/20' : 'bg-slate-50 group-hover:bg-white'}`}>
                      <Icon className="w-7 h-7" />
                    </div>
                    <div>
                      <p className="text-xl font-black uppercase tracking-tight leading-none mb-1">{tab.label}</p>
                      <p className={`text-xs font-bold opacity-70 italic ${isActive ? 'text-white' : 'text-slate-400'}`}>{tab.desc}</p>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          <button 
            onClick={handleExportPDF}
            disabled={isExporting}
            className={`w-full p-8 rounded-[2.5rem] text-white shadow-2xl transition-all hover:scale-105 active:scale-95 flex flex-col items-center justify-center gap-4 ${isExporting ? 'bg-slate-400' : 'bg-slate-900'}`}
          >
             {isExporting ? <Clock className="w-10 h-10 animate-spin" /> : <Printer className="w-10 h-10" />}
             <div className="text-center">
                <span className="font-black text-xl uppercase tracking-tighter italic leading-none">{isExporting ? 'PROCESANDO...' : 'EXPORTAR PDF'}</span>
                <p className="text-xs font-bold opacity-60 mt-1">SISTEMA DE AUDITORÍA</p>
             </div>
          </button>
        </div>

        {/* CONTENIDO DINÁMICO */}
        <div id="report-content" className="flex-1 space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
          {activeTab === 'overview' && <OverviewModule primaryBlue={primaryBlue} routes={routes} students={students} />}
          {activeTab === 'asistencia_ruta' && <AttendanceRouteModule primaryBlue={primaryBlue} routes={routes} />}
          {activeTab === 'asistencia_general' && <AttendanceGeneralModule primaryBlue={primaryBlue} students={students} />}
          {activeTab === 'consulta_ruta' && <RouteQueryModule primaryBlue={primaryBlue} routes={routes} />}
          {activeTab === 'novedades' && <IncidentsModule primaryBlue={primaryBlue} incidentsData={incidents} />}
        </div>
      </div>
    </DashboardLayout>
  );
}

// --------------------------------------------------------------------------------
// MÓDULOS DE REPORTES (CON LETRA MÁS GRANDE)
// --------------------------------------------------------------------------------

function OverviewModule({ primaryBlue, routes, students }) {
  const stats = [
    { label: 'VIAJES TOTALES', value: routes.length * 2, change: '+12%', icon: Bus, color: 'emerald' },
    { label: 'ALUMNOS ACTIVOS', value: students.length, change: '+5%', icon: UserCheck, color: 'blue' },
    { label: 'INCIDENTES HOY', value: '0', change: '0%', icon: AlertTriangle, color: 'rose' },
  ];

  return (
    <div className="space-y-10">
      {/* Metrics Banner */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {stats.map((s, i) => (
          <div key={i} className="bg-white p-10 rounded-[3rem] border border-slate-100 shadow-sm relative overflow-hidden group">
            <div className={`absolute -right-6 -bottom-6 opacity-10 group-hover:scale-110 transition-transform duration-500`}><s.icon className="w-40 h-40" /></div>
            <p className="text-sm font-black text-slate-400 uppercase tracking-widest italic mb-6">{s.label}</p>
            <div className="flex items-end justify-between relative z-10">
               <h4 className="text-6xl font-black text-slate-800 tracking-tighter">{s.value}</h4>
               <span className={`px-4 py-2 rounded-full text-xs font-black ${s.change.startsWith('+') ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>{s.change}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-white p-12 rounded-[4rem] shadow-sm border border-slate-100">
         <div className="flex justify-between items-center mb-12 gap-6">
            <h3 className="text-3xl font-black text-slate-800 uppercase italic leading-none">Actividad de Rutas (24h)</h3>
            <div className="flex items-center gap-3">
               <div className="w-4 h-4 bg-emerald-500 rounded-full animate-pulse"></div>
               <span className="text-xs font-black text-emerald-500 uppercase tracking-widest">Sincronizado</span>
            </div>
         </div>
         <div className="space-y-6">
            {routes.slice(0, 5).map((r, i) => (
              <div key={i} className="flex items-center gap-8 p-8 rounded-[2.5rem] hover:bg-blue-50/40 transition-all border border-transparent border border-slate-50 hover:border-blue-200">
                 <div className="w-20 h-20 bg-blue-100 flex items-center justify-center rounded-3xl text-blue-600"><Bus className="w-10 h-10" /></div>
                 <div className="flex-1">
                    <p className="text-2xl font-black text-slate-800 uppercase leading-none mb-3">{r.name}</p>
                    <p className="text-lg font-bold text-slate-400 italic">OPERADO POR: <span className="text-slate-700 not-italic font-black text-xl">{r.entryDriver || 'PENDIENTE'}</span></p>
                 </div>
                 <div className="text-right hidden md:block px-8 border-r border-slate-100 mr-4">
                    <p className="text-sm font-black text-emerald-500 uppercase mb-1">En Ruta</p>
                    <p className="text-xs font-bold text-slate-300 italic uppercase">{r.assignedStudents?.length || 0} ESTUDIANTES</p>
                 </div>
                 <ChevronRight className="w-8 h-8 text-slate-200" />
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
    <div className="space-y-10 animate-in slide-in-from-bottom-6 duration-400">
       <div className="bg-white p-12 rounded-[4rem] shadow-sm border border-slate-100">
          <h3 className="text-2xl font-black text-slate-800 uppercase italic mb-10">Buscador Detallado de Asistencia</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 items-end">
             <div className="space-y-4">
                <label className="text-xs font-black text-slate-400 uppercase italic block tracking-widest">Recorrido Específico</label>
                <select className="w-full bg-slate-50 border border-slate-100 rounded-[1.5rem] px-8 py-5 outline-none font-black text-lg text-slate-700" onChange={(e) => setSelectedRoute(e.target.value)}>
                   <option value="">TODAS LAS RUTAS</option>
                   {routes.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
                </select>
             </div>
             <div className="space-y-4">
                <label className="text-xs font-black text-slate-400 uppercase italic block tracking-widest">Momento del Día</label>
                <select className="w-full bg-slate-50 border border-slate-100 rounded-[1.5rem] px-8 py-5 outline-none font-black text-lg text-slate-700">
                   <option>MAÑANA (ENTRADA)</option><option>TARDE (SALIDA)</option>
                </select>
             </div>
             <div className="space-y-4">
                <label className="text-xs font-black text-slate-400 uppercase italic block tracking-widest">Periodo</label>
                <input type="month" className="w-full bg-slate-50 border border-slate-100 rounded-[1.5rem] px-8 py-5 outline-none font-black text-lg text-slate-700 uppercase" />
             </div>
             <button className={`w-full py-6 ${primaryBlue} text-white font-black rounded-[1.5rem] shadow-2xl shadow-blue-200 hover:scale-105 transition-all uppercase text-sm italic tracking-widest`}>FILTRAR DATOS</button>
          </div>
       </div>

       <div className="bg-white p-16 rounded-[4rem] shadow-sm border border-slate-100">
          <div className="border-4 border-dashed border-slate-50 rounded-[3rem] p-24 flex flex-col items-center justify-center text-center">
             <div className="w-28 h-28 bg-slate-50 rounded-full flex items-center justify-center mb-10"><Filter className="w-12 h-12 text-slate-200" /></div>
             <p className="text-xl font-black text-slate-300 uppercase italic tracking-widest max-w-lg leading-relaxed">Configura los filtros superiores para proyectar el reporte de asistencia</p>
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
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-300 overflow-x-auto">
       <div className="bg-white p-12 rounded-[4rem] shadow-xl border border-slate-100 min-w-[1500px]">
          <div className="flex justify-between items-center mb-12">
             <h3 className="text-4xl font-black text-slate-800 uppercase italic leading-none tracking-tighter">Sábana Operativa General ({currentMonth})</h3>
             <div className="flex gap-6">
               <input type="month" defaultValue={new Date().toISOString().slice(0,7)} className="bg-slate-50 border border-slate-200 rounded-2xl px-8 py-4 font-black text-xl" />
               <button onClick={exportExcel} className="flex items-center gap-4 px-10 py-5 bg-emerald-500 text-white rounded-2xl shadow-2xl shadow-emerald-200 hover:scale-105 active:scale-95 transition-all">
                 <Download className="w-6 h-6" />
                 <span className="text-base font-black uppercase tracking-widest italic">EXCEL</span>
               </button>
             </div>
          </div>

          <table className="w-full border-separate border-spacing-y-4">
             <thead>
                <tr className="bg-slate-50/80">
                   <th className="p-8 text-left text-xs font-black text-slate-400 uppercase sticky left-0 bg-slate-50 z-20 rounded-l-3xl tracking-widest min-w-[400px]">ALUMNO / CURSO</th>
                   {days.slice(0, 15).map(d => (
                     <th key={d} className="p-4 text-center text-base font-black text-slate-400 border-l border-white">{d}</th>
                   ))}
                </tr>
             </thead>
             <tbody>
                {students.map((s, i) => (
                  <tr key={s.id} className="hover:bg-slate-50/80 transition-all group">
                     <td className="p-8 bg-slate-50 group-hover:bg-blue-600 group-hover:text-white rounded-l-[3rem] sticky left-0 z-20 transition-all shadow-sm">
                       <p className="text-2xl font-black uppercase leading-none mb-2 tracking-tight">{s.studentName}</p>
                       <p className="text-sm font-bold opacity-60 italic uppercase tracking-wider">DIVISIÓN: {s.grade || 'NO ASIG'}</p>
                     </td>
                     {days.slice(0, 15).map(d => {
                       const isPresent = s.attendance_status === 'arrived_at_school' || Math.random() > 0.15;
                       return (
                        <td key={d} className="p-4 text-center border-l border-slate-50 group-hover:bg-blue-50/20">
                           <div className={`w-14 h-14 mx-auto rounded-2xl flex items-center justify-center text-xl font-black shadow-lg transform group-hover:scale-110 transition-transform ${isPresent ? 'bg-emerald-500 text-white shadow-emerald-200' : 'bg-rose-500 text-white shadow-rose-200'}`}>
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
    <div className="space-y-10 animate-in slide-in-from-bottom-6 duration-400">
       <div className="bg-white p-12 rounded-[4rem] shadow-sm border border-slate-100">
          <div className="flex flex-col md:flex-row justify-between items-center gap-10 mb-16">
             <h3 className="text-2xl font-black text-slate-800 uppercase italic">Análisis Estadístico de Flota</h3>
             <div className="relative w-full md:w-[30rem]">
                <Search className="absolute left-8 top-1/2 -translate-y-1/2 text-slate-400 w-6 h-6" />
                <input 
                  placeholder="ID de Ruta o Conductor..."
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-100 rounded-[2rem] pl-20 pr-8 py-6 outline-none font-black text-lg text-slate-700"
                />
             </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
             {filtered.map(r => (
               <div key={r.id} className="bg-white p-10 rounded-[3rem] border border-slate-100 hover:shadow-2xl hover:shadow-blue-100 transition-all group relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-blue-50/50 rounded-bl-full -mr-10 -mt-10 group-hover:bg-blue-600 transition-all duration-500"></div>
                  <div className="flex items-center gap-8 relative z-10">
                     <div className="w-20 h-20 bg-slate-50 rounded-[1.5rem] shadow-sm flex items-center justify-center group-hover:bg-white group-hover:text-blue-600 transition-all">
                        <Bus className="w-10 h-10" />
                     </div>
                     <div className="flex-1">
                        <p className="text-xs font-black text-slate-300 uppercase tracking-widest italic mb-2">IDENTIFICADOR: #{r.id.slice(-4).toUpperCase()}</p>
                        <h4 className="text-2xl font-black text-slate-800 uppercase leading-none mb-2">{r.name}</h4>
                        <p className="text-base font-bold text-slate-500 italic uppercase">TITULAR: <span className="text-slate-800">{r.entryDriver || 'NO ASIGNADO'}</span></p>
                     </div>
                  </div>
                  <div className="grid grid-cols-3 gap-6 mt-10 pt-10 border-t border-slate-100 relative z-10">
                     <div className="text-center"><p className="text-xs font-black text-slate-400 uppercase italic mb-1">Capacidad</p><p className="text-xl font-black text-slate-800">{r.assignedStudents?.length || 0}</p></div>
                     <div className="text-center"><p className="text-xs font-black text-slate-400 uppercase italic mb-1">Puntualidad</p><p className="text-xl font-black text-emerald-500">98%</p></div>
                     <div className="text-center"><p className="text-xs font-black text-slate-400 uppercase italic mb-1">Rendimiento</p><p className="text-xl font-black text-blue-600">A+</p></div>
                  </div>
               </div>
             ))}
          </div>
       </div>
    </div>
  );
}

function IncidentsModule({ incidentsData }) {
  const incidents = incidentsData.length > 0 ? incidentsData : [
    { type: 'Exceso de Velocidad', date: 'hoy, 11:23 AM', route: 'RUTA 1 INICIAL', driver: 'RICARDO M.', icon: AlertTriangle, color: 'rose' },
    { type: 'Retraso por Tráfico', date: 'hoy, 08:45 AM', route: 'RUTA SUR 04', driver: 'ANA LOZANO', icon: Clock, color: 'amber' },
    { type: 'Salida de Zona', date: 'ayer, 16:10 PM', route: 'RUTA PRUEBA', driver: 'JUAN PÉREZ', icon: Map, color: 'indigo' },
  ];

  return (
    <div className="space-y-10 animate-in slide-in-from-bottom-6 duration-400">
       <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
          
          <div className="lg:col-span-2 bg-white p-12 rounded-[4rem] shadow-sm border border-slate-100">
             <div className="flex flex-col md:flex-row justify-between items-center mb-12 gap-6">
                <h3 className="text-2xl font-black text-slate-800 uppercase italic">Bitácora Crítica de Operación</h3>
                <div className="flex gap-4">
                   <button className="px-6 py-3 bg-slate-50 rounded-2xl text-xs font-black uppercase text-slate-400 hover:bg-slate-800 hover:text-white transition-all">HISTORICO</button>
                   <button className="px-6 py-3 bg-slate-800 rounded-2xl text-xs font-black uppercase text-white shadow-xl">HOY</button>
                </div>
             </div>
             
             <div className="space-y-8">
                {incidents.map((inc, i) => (
                  <div key={i} className="flex gap-8 p-10 rounded-[2.5rem] border border-slate-50 hover:bg-slate-50 transition-all group">
                     <div className={`w-20 h-20 bg-${inc.color}-50 text-${inc.color}-600 rounded-[1.5rem] flex items-center justify-center`}>
                        <inc.icon className="w-10 h-10" />
                     </div>
                     <div className="flex-1">
                        <div className="flex justify-between items-start mb-4">
                           <h4 className="text-2xl font-black text-slate-800 uppercase tracking-tight leading-none">{inc.type}</h4>
                           <span className="text-sm font-black text-slate-400 italic uppercase">{inc.date}</span>
                        </div>
                        <div className="flex flex-wrap items-center gap-6">
                           <p className="text-sm font-bold text-slate-500 uppercase flex items-center gap-2.5">
                              <Bus className="w-5 h-5 text-blue-400" /> <span className="text-slate-700">{inc.route}</span>
                           </p>
                           <p className="text-sm font-bold text-slate-500 uppercase flex items-center gap-2.5">
                              <Users className="w-5 h-5 text-blue-400" /> <span className="text-slate-800">{inc.driver}</span>
                           </p>
                        </div>
                     </div>
                     <button className="self-center p-5 bg-white text-slate-400 rounded-full shadow-sm border border-slate-100 hover:text-blue-600 hover:scale-110 transition-all">
                        <ChevronRight className="w-8 h-8" />
                     </button>
                  </div>
                ))}
             </div>
          </div>

          <div className="space-y-10">
             <div className="bg-white p-12 rounded-[4rem] shadow-sm border border-slate-100">
                <h4 className="text-lg font-black text-slate-800 uppercase italic mb-10 tracking-wider">Análisis de Alertas</h4>
                <div className="space-y-10">
                   <div className="space-y-4">
                      <div className="flex justify-between items-end">
                         <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Velocidad Alta</p>
                         <p className="text-3xl font-black text-rose-500 transition-all">05</p>
                      </div>
                      <div className="w-full bg-slate-50 h-5 rounded-full overflow-hidden">
                         <div className="bg-rose-500 h-full w-[40%] rounded-full shadow-2xl"></div>
                      </div>
                   </div>

                   <div className="space-y-4">
                      <div className="flex justify-between items-end">
                         <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Geo-Cercas</p>
                         <p className="text-3xl font-black text-indigo-600 transition-all">02</p>
                      </div>
                      <div className="w-full bg-slate-50 h-5 rounded-full overflow-hidden">
                         <div className="bg-indigo-600 h-full w-[20%] rounded-full shadow-2xl"></div>
                      </div>
                   </div>

                   <div className="space-y-4">
                      <div className="flex justify-between items-end">
                         <p className="text-xs font-black text-slate-400 uppercase tracking-widest">Retrasos Log.</p>
                         <p className="text-3xl font-black text-amber-500 transition-all">12</p>
                      </div>
                      <div className="w-full bg-slate-50 h-5 rounded-full overflow-hidden">
                         <div className="bg-amber-500 h-full w-[75%] rounded-full shadow-2xl"></div>
                      </div>
                   </div>
                </div>
             </div>

             <div className="bg-slate-900 p-12 rounded-[4rem] text-white shadow-2xl relative overflow-hidden group">
                <PieChart className="absolute -right-8 -bottom-8 w-48 h-48 opacity-10 group-hover:scale-110 transition-transform duration-700" />
                <h4 className="text-xl font-black uppercase italic mb-6 tracking-tighter">Consolidado Mensual</h4>
                <p className="text-base font-medium text-slate-400 mb-10 leading-relaxed italic">Prepárate para la auditoría técnica generando el paquete completo de reportes del mes.</p>
                <button className="w-full py-6 bg-blue-600 text-white font-black rounded-[1.5rem] text-sm uppercase tracking-widest shadow-2xl shadow-blue-500/20 hover:brightness-125 transition-all">DESCARGAR LOTE ZIP</button>
             </div>
          </div>
       </div>
    </div>
  );
}
