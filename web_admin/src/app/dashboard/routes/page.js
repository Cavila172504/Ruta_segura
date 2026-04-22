'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, onSnapshot, query, addDoc, serverTimestamp, doc, updateDoc, deleteDoc, orderBy } from 'firebase/firestore';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { Truck, MapPin, ChevronDown, ChevronUp, Map, Download, Plus, Trash2, Save, X, Eye, Search, AlertCircle, User, CreditCard, HelpCircle, Info } from 'lucide-react';
import dynamic from 'next/dynamic';
import 'leaflet/dist/leaflet.css';

const MapContainer = dynamic(() => import('react-leaflet').then(m => m.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import('react-leaflet').then(m => m.TileLayer), { ssr: false });
const Marker = dynamic(() => import('react-leaflet').then(m => m.Marker), { ssr: false });

export default function RoutesPage() {
  const [routes, setRoutes] = useState([]);
  const [students, setStudents] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  
  const [showCreate, setShowCreate] = useState(false);
  const [expandedRoute, setExpandedRoute] = useState(null);
  const [studentMapData, setStudentMapData] = useState(null);
  const [showStudentPicker, setShowStudentPicker] = useState(null);
  const [studentSearch, setStudentSearch] = useState('');
  const [L, setL] = useState(null);
  const [syncStatus, setSyncStatus] = useState({}); // { routeId: 'synced' | 'pending' }

  const { profile, loading: authLoading, SCHOOL_CODE } = useAuth();
  const days = ['L', 'M', 'MI', 'J', 'V', 'S', 'D'];
  
  // Colores Institucionales Suaves
  const primaryBlue = 'bg-[#4361ee]'; // Azul suave institucional
  const primaryBlueText = 'text-[#4361ee]';

  useEffect(() => {
    if (authLoading || !SCHOOL_CODE) return;

    import('leaflet').then((leaflet) => setL(leaflet.default));
    const unsubRoutes = onSnapshot(query(collection(db, 'companies', SCHOOL_CODE, 'routes'), orderBy('createdAt', 'desc')), (snap) => {
      setRoutes(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubStudents = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'students'), (snap) => {
      setStudents(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubDrivers = onSnapshot(collection(db, 'companies', SCHOOL_CODE, 'drivers'), (snap) => {
      setDrivers(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });
    return () => { unsubRoutes(); unsubStudents(); unsubDrivers(); };
  }, [SCHOOL_CODE, authLoading]);

  const handleSaveNewRoute = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    try {
      await addDoc(collection(db, 'companies', SCHOOL_CODE, 'routes'), {
        name: formData.get('name') || 'SIN NOMBRE',
        shift: formData.get('shift') || 'MATUTINA',
        entryDriver: formData.get('driverName') || '',
        driverId: formData.get('driverId') || '',
        entryUnit: formData.get('unit') || 'S/N',
        assignedStudents: [],
        status: 'active',
        createdAt: serverTimestamp()
      });
      setShowCreate(false);
      alert('Ruta Guardada');
    } catch (e) { alert('Error: ' + e.message); }
  };

  const addStudentToRoute = async (routeId, student) => {
    const route = routes.find(r => r.id === routeId);
    if (route.assignedStudents?.some(s => s.id === student.id)) return;
    const newAssigned = [...(route.assignedStudents || []), {
      id: student.id,
      studentName: student.studentName,
      grade: student.grade,
      serviceType: student.serviceType || 'COMPLETO',
      stopLat: student.stopLat,
      stopLng: student.stopLng,
      matrix: days.reduce((acc, d) => ({ ...acc, [d]: { entrance: 'confirmed', exit: 'confirmed' } }), {})
    }];
    await updateDoc(doc(db, 'companies', SCHOOL_CODE, 'routes', routeId), { assignedStudents: newAssigned });
    
    // Vincular al estudiante con el conductor en su documento principal
    if (route.driverId) {
      await updateDoc(doc(db, 'companies', SCHOOL_CODE, 'students', student.id), { 
        driverId: route.driverId,
        assignedRoute: route.name,
        status: 'active'
      });
    }
    setSyncStatus(prev => ({ ...prev, [routeId]: 'pending' }));
  };

  const updateStudentService = async (routeId, studentId, newService) => {
    const route = routes.find(r => r.id === routeId);
    const newAssigned = route.assignedStudents.map(s => s.id === studentId ? { ...s, serviceType: newService } : s);
    await updateDoc(doc(db, 'companies', SCHOOL_CODE, 'routes', routeId), { assignedStudents: newAssigned });
    setSyncStatus(prev => ({ ...prev, [routeId]: 'pending' }));
  };

  const updateMatrixCell = async (routeId, studentId, day, type, currentStatus) => {
    const cycle = { 'confirmed': 'maybe', 'maybe': 'no', 'no': 'confirmed' };
    const nextStatus = cycle[currentStatus] || 'confirmed';
    const route = routes.find(r => r.id === routeId);
    const newAssigned = route.assignedStudents.map(s => {
      if (s.id === studentId) { return { ...s, matrix: { ...s.matrix, [day]: { ...s.matrix[day], [type]: nextStatus } } }; }
      return s;
    });
    await updateDoc(doc(db, 'companies', SCHOOL_CODE, 'routes', routeId), { assignedStudents: newAssigned });
    setSyncStatus(prev => ({ ...prev, [routeId]: 'pending' }));
  };

  const removeStudentFromRoute = async (routeId, studentId) => {
    const route = routes.find(r => r.id === routeId);
    const newAssigned = route.assignedStudents.filter(s => s.id !== studentId);
    await updateDoc(doc(db, 'companies', SCHOOL_CODE, 'routes', routeId), { assignedStudents: newAssigned });
    
    await updateDoc(doc(db, 'companies', SCHOOL_CODE, 'students', studentId), {
      driverId: null,
      assignedRoute: null
    });

    setSyncStatus(prev => ({ ...prev, [routeId]: 'pending' }));
  };

  const handleSync = async (routeId) => {
    try {
      const routeRef = doc(db, 'companies', SCHOOL_CODE, 'routes', routeId);
      await updateDoc(routeRef, { 
        lastSync: serverTimestamp(),
        status: 'active' 
      });
      setSyncStatus(prev => ({ ...prev, [routeId]: 'synced' }));
      alert('🚀 ¡HOJA DE RUTA SINCRONIZADA! El conductor ya puede ver los cambios.');
    } catch (e) {
      alert('Error en la sincronización: ' + e.message);
    }
  };

  return (
    <DashboardLayout title="Centro de Comando de Rutas">
      <div className="max-w-[1600px] mx-auto space-y-8 pb-20">
        
        {/* CABECERA (Azul Suave) */}
        <div className="bg-white p-4 sm:p-6 rounded-2xl flex flex-col-reverse sm:flex-row justify-between items-start sm:items-center shadow-sm border border-slate-100 gap-4">
           {profile?.role !== 'viewer' ? (
             <button onClick={() => setShowCreate(!showCreate)} className={`flex items-center justify-center gap-2 w-full sm:w-auto px-6 py-3 ${primaryBlue} text-white rounded-xl font-black text-sm hover:brightness-110 transition-all shadow-lg shadow-blue-200 active:scale-95`}>
                {showCreate ? <X className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
                {showCreate ? 'CANCELAR' : 'NUEVA RUTA TÁCTICA'}
             </button>
           ) : (
             <div className="flex items-center gap-2 text-slate-400 font-bold text-xs uppercase tracking-widest px-4">
               <Eye className="w-4 h-4" /> Modo Monitoreo
             </div>
           )}
           <div className="text-left sm:text-right w-full sm:w-auto">
              <p className="text-[10px] sm:text-sm font-black text-slate-400 uppercase italic tracking-widest mb-0 sm:mb-1">RutaSegura Global</p>
              <p className={`text-xl sm:text-2xl font-black ${primaryBlueText} tracking-tighter italic uppercase`}>Panel Gestión</p>
           </div>
        </div>

        {/* CREACIÓN */}
        {showCreate && (
          <form onSubmit={handleSaveNewRoute} className="bg-white p-4 sm:p-6 rounded-2xl shadow-md border border-blue-50 animate-in slide-in-from-top duration-300">
             <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-6">
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-1 block tracking-widest">Nombre de Ruta</label>
                   <input name="name" placeholder="Ej: RUTA 1" className="w-full bg-slate-50 border border-slate-100 rounded-lg px-4 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-400 font-bold" />
                </div>
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-1 block tracking-widest">Jornada</label>
                   <select name="shift" className="w-full bg-slate-50 border border-slate-100 rounded-lg px-4 py-2 text-sm outline-none font-bold">
                      <option>MATUTINA</option><option>VESPERTINA</option><option>NOCTURNA</option>
                   </select>
                </div>
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-1 block tracking-widest">Conductor</label>
                    <select name="driverId" onChange={(e) => {
                      const selected = drivers.find(d => (d.uid || d.id) === e.target.value);
                      document.getElementById('selected_driver_name').value = selected ? (selected.name || `${selected.names} ${selected.lastNames}`) : '';
                    }} className="w-full bg-slate-50 border border-slate-100 rounded-lg px-4 py-2 text-sm outline-none font-bold">
                       <option value="">Seleccionar...</option>
                       {drivers.map(d => <option key={d.id} value={d.uid || d.id}>{d.name || `${d.names} ${d.lastNames}`}</option>)}
                    </select>
                    <input type="hidden" id="selected_driver_name" name="driverName" />
                </div>
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-1 block tracking-widest">Placa / Unidad</label>
                   <input name="unit" placeholder="Ej: P-10" className="w-full bg-slate-50 border border-slate-100 rounded-lg px-4 py-2 text-sm outline-none font-bold" />
                </div>
             </div>
             <div className="flex justify-end gap-2"><button type="submit" className={`w-full sm:w-auto px-6 py-2.5 ${primaryBlue} text-white text-sm font-black rounded-lg shadow-md shadow-blue-100 hover:scale-105 active:scale-95 transition-all`}>GUARDAR RUTA</button></div>
          </form>
        )}

        {/* LISTADO DE RUTAS */}
        <div className="space-y-4 sm:space-y-6">
           {routes.map(route => (
             <div key={route.id} className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex flex-col hover:border-blue-200 transition-all">
                
                {/* HEAD DE RUTA (CON CONDUCTOR Y PLACA) */}
                <div className="p-4 sm:p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 sm:gap-6">
                   <div className="flex items-center gap-4">
                      <div className={`hidden sm:flex w-16 h-16 ${primaryBlue} bg-opacity-10 rounded-xl items-center justify-center`}><Truck className={`w-8 h-8 ${primaryBlueText}`} /></div>
                      <div>
                         <h3 className="text-lg sm:text-xl font-black text-slate-800 uppercase tracking-tighter leading-none mb-2 italic">{route.name}</h3>
                         <div className="flex flex-wrap gap-2 sm:gap-4">
                            <span className={`text-[10px] sm:text-xs font-black ${primaryBlue} text-white px-3 py-1 rounded-md italic uppercase tracking-widest shadow-sm`}>{route.shift}</span>
                            <span className="flex items-center gap-1 text-[10px] sm:text-xs font-bold text-slate-500 uppercase"><User className="w-4 h-4 text-blue-500" /> <span className="text-slate-900 font-black">{route.entryDriver || 'PENDIENTE'}</span></span>
                            <span className="flex items-center gap-1 text-[10px] sm:text-xs font-bold text-slate-500 uppercase"><CreditCard className="w-4 h-4 text-blue-500" /> PLACA: <span className="text-slate-900 font-black">{route.entryUnit || 'S/N'}</span></span>
                         </div>
                      </div>
                   </div>

                   <div className="flex w-full sm:w-auto gap-2 sm:gap-4">
                      <button 
                        onClick={() => setExpandedRoute(expandedRoute === route.id ? null : route.id)}
                        className={`flex-1 sm:flex-none flex justify-center items-center gap-2 px-4 sm:px-6 py-2 sm:py-3 rounded-xl font-black text-[10px] sm:text-xs transition-all shadow-sm hover:scale-105 ${expandedRoute === route.id ? 'bg-amber-100 text-amber-700 shadow-amber-100' : 'bg-slate-900 text-white hover:bg-black shadow-slate-200'}`}
                      >
                         {expandedRoute === route.id ? 'CERRAR PANEL' : (profile?.role === 'viewer' ? 'VER PASAJEROS' : 'GESTIONAR PASAJEROS')}
                         {expandedRoute === route.id ? <ChevronUp className="w-4 h-4 sm:w-5 sm:h-5" /> : <ChevronDown className="w-4 h-4 sm:w-5 sm:h-5" />}
                      </button>
                      {profile?.role !== 'viewer' && <button onClick={() => deleteDoc(doc(db, 'companies', SCHOOL_CODE, 'routes', route.id))} className="w-10 h-10 sm:w-12 sm:h-auto flex items-center justify-center bg-rose-50 text-rose-300 hover:bg-rose-500 hover:text-white rounded-xl transition-all shadow-sm"><Trash2 className="w-4 h-4 sm:w-5 sm:h-5" /></button>}
                   </div>
                </div>

                {/* CUERPO TÁCTICO */}
                {expandedRoute === route.id && (
                  <div className="p-4 sm:p-6 bg-slate-50 border-t border-slate-100 space-y-4 sm:space-y-6 animate-in slide-in-from-top duration-300 relative">
                     
                     <div className="flex flex-col xl:flex-row justify-between items-start xl:items-center gap-4">
                        {profile?.role !== 'viewer' && (
                          <button onClick={() => setShowStudentPicker(route.id)} className={`flex items-center justify-center w-full sm:w-auto gap-2 px-6 py-3 ${primaryBlue} text-white rounded-xl font-black text-xs hover:scale-105 transition-all shadow-md shadow-blue-100`}>
                             <Plus className="w-4 h-4 text-white" /> AGREGAR ESTUDIANTES A RUTA
                          </button>
                        )}
                        
                        {/* LEYENDA TÁCTICA */}
                        <div className="flex flex-wrap items-center gap-2 sm:gap-4 bg-white px-4 py-2.5 rounded-xl border border-slate-200 shadow-sm w-full sm:w-auto justify-center sm:justify-start">
                           <div className="flex items-center gap-1"><span className="text-[10px] font-black text-slate-400 hidden sm:inline">SIGNIFICADOS:</span></div>
                           <div className="flex items-center gap-1"><div className="w-5 h-5 bg-emerald-500 text-white flex items-center justify-center rounded text-[10px] font-black">E</div><span className="text-[10px] font-bold text-slate-500 hidden sm:inline">ENTRADA</span></div>
                           <div className="flex items-center gap-1"><div className="w-5 h-5 bg-emerald-500 text-white flex items-center justify-center rounded text-[10px] font-black">S</div><span className="text-[10px] font-bold text-slate-500 hidden sm:inline">SALIDA</span></div>
                           <div className="w-px h-4 bg-slate-200 mx-1 hidden sm:block"></div>
                           <div className="flex items-center gap-1"><div className="w-2.5 h-2.5 bg-emerald-500 rounded-full"></div><span className="text-[10px] font-bold text-slate-500 uppercase">Asiste</span></div>
                           <div className="flex items-center gap-1"><div className="w-2.5 h-2.5 bg-slate-200 rounded-full"></div><span className="text-[10px] font-bold text-slate-500 uppercase">Posible</span></div>
                           <div className="flex items-center gap-1"><div className="w-2.5 h-2.5 bg-red-500 rounded-full"></div><span className="text-[10px] font-bold text-slate-500 uppercase">Falta</span></div>
                        </div>
                     </div>

                     <div className="bg-white rounded-2xl shadow-md border border-slate-200 overflow-hidden">
                        <div className="overflow-x-auto">
                          <table className="w-full text-left min-w-[800px]">
                             <thead className={`${primaryBlue} text-white`}>
                                <tr className="text-[10px] font-black uppercase tracking-widest italic">
                                   <th className="px-4 py-3">#</th>
                                   <th className="px-4 py-3">Estudiante</th>
                                   <th className="px-4 py-3">Tipo Servicio</th>
                                   <th className="px-4 py-3 text-center italic">Mapa</th>
                                   {days.map(d => <th key={d} className="px-2 py-3 text-center border-l border-white/10">{d}</th>)}
                                   {profile?.role !== 'viewer' && <th className="px-4 py-3 text-center text-red-200">Quitar</th>}
                                </tr>
                             </thead>
                             <tbody className="divide-y divide-slate-50">
                                {route.assignedStudents?.map((s, idx) => (
                                  <tr key={s.id} className="hover:bg-blue-50/50 transition-all border-b border-slate-50">
                                     <td className="px-4 py-3 text-xs font-bold text-slate-400">{idx + 1}</td>
                                     <td className="px-4 py-3">
                                        <p className="font-black text-xs uppercase text-slate-800 tracking-tight leading-none mb-1">{s.studentName}</p>
                                        <p className="text-[10px] font-bold text-slate-400 italic uppercase">DIVISIÓN: {s.grade || 'CADE'}</p>
                                     </td>
                                     <td className="px-4 py-3">
                                        <select 
                                          value={s.serviceType || 'COMPLETO'}
                                          onChange={(e) => updateStudentService(route.id, s.id, e.target.value)}
                                          className="bg-slate-50 border border-slate-100 rounded-lg px-2 py-1 text-[10px] font-black text-slate-600 uppercase outline-none focus:ring-2 focus:ring-blue-100"
                                        >
                                           <option>COMPLETO</option><option>SOLO IDA</option><option>SOLO RETORNO</option>
                                        </select>
                                     </td>
                                     <td className="px-4 py-3 text-center">
                                        <button onClick={() => setStudentMapData(s)} className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center hover:bg-blue-600 hover:text-white transition-all mx-auto shadow-sm"><MapPin className="w-4 h-4" /></button>
                                     </td>
                                     {days.map(d => {
                                        const m = s.matrix?.[d] || { entrance: 'confirmed', exit: 'confirmed' };
                                        return (
                                          <td key={d} className="px-2 py-2 border-l border-slate-50">
                                             <div className="flex flex-col gap-1.5 items-center">
                                                <button onClick={() => profile?.role !== 'viewer' && updateMatrixCell(route.id, s.id, d, 'entrance', m.entrance)} className={`w-8 h-6 rounded flex items-center justify-center text-[10px] font-black transition-all ${m.entrance === 'confirmed' ? 'bg-emerald-500 text-white shadow-sm' : m.entrance === 'maybe' ? 'bg-slate-200 text-slate-500' : 'bg-red-500 text-white shadow-sm'} ${profile?.role === 'viewer' ? 'cursor-default' : ''}`}>E</button>
                                                <button onClick={() => profile?.role !== 'viewer' && updateMatrixCell(route.id, s.id, d, 'entrance', m.entrance)} className={`w-8 h-6 rounded flex items-center justify-center text-[10px] font-black transition-all ${m.exit === 'confirmed' ? 'bg-emerald-500 text-white shadow-sm' : m.exit === 'maybe' ? 'bg-slate-200 text-slate-500' : 'bg-red-500 text-white shadow-sm'} ${profile?.role === 'viewer' ? 'cursor-default' : ''}`}>S</button>
                                             </div>
                                          </td>
                                        )
                                     })}
                                     {profile?.role !== 'viewer' && (
                                       <td className="px-4 py-3 text-center">
                                          <button onClick={() => removeStudentFromRoute(route.id, s.id)} className="w-8 h-8 flex items-center justify-center text-slate-300 hover:text-red-500 hover:bg-red-50 rounded-lg transition-all mx-auto"><X className="w-5 h-5" /></button>
                                       </td>
                                     )}
                                  </tr>
                              ))}
                                {!route.assignedStudents?.length && (
                                  <tr><td colSpan={11} className="py-10 text-center text-[10px] font-black text-slate-400 uppercase italic tracking-widest animate-pulse">Haz clic en &quot;AGREGAR ESTUDIANTES&quot; para iniciar la hoja de ruta</td></tr>
                                )}
                             </tbody>
                          </table>
                        </div>
                        <div className="p-4 sm:p-6 bg-slate-50 border-t border-slate-100 flex justify-end">
                           {profile?.role !== 'viewer' && (
                               <button 
                                 onClick={() => handleSync(route.id)} 
                                 className={`flex w-full sm:w-auto justify-center items-center gap-2 px-6 py-3 text-white font-black rounded-xl text-xs uppercase shadow-md transition-all hover:scale-105 active:scale-95 ${syncStatus[route.id] === 'synced' ? 'bg-slate-400 shadow-slate-200' : 'bg-emerald-500 shadow-emerald-200'}`}
                               >
                                  <Save className="w-4 h-4" /> 
                                  {syncStatus[route.id] === 'synced' ? '¡SINCRO EXITOSA!' : 'ACTUALIZAR Y SINCRONIZAR'}
                               </button>
                            )}
                        </div>
                     </div>
                  </div>
                )}
             </div>
           ))}
        </div>
      </div>

      {/* SELECTOR AZUL (MODAL LATERAL) */}
      {showStudentPicker && (
        <div className="fixed inset-0 z-[4000] bg-slate-900/40 backdrop-blur-md flex items-center justify-end">
           <div className="bg-white w-full max-w-md h-full shadow-2xl animate-in slide-in-from-right duration-500 flex flex-col">
              <div className={`p-8 ${primaryBlue} text-white flex justify-between items-center`}>
                 <div><h2 className="text-xl font-black italic tracking-tighter">AGREGAR ALUMNOS</h2><p className="text-[10px] font-bold text-white/70 uppercase">PROCESO TÁCTICO</p></div>
                 <button onClick={() => setShowStudentPicker(null)} className="w-12 h-12 bg-white/10 rounded-full flex items-center justify-center hover:bg-white/20"><X className="w-6 h-6" /></button>
              </div>
              <div className="p-6 border-b border-slate-100 relative">
                 <Search className={`w-5 h-5 absolute left-10 top-11 ${primaryBlueText}`} />
                 <input placeholder="Escribe el nombre..." className="w-full bg-slate-50 border border-slate-200 rounded-2xl pl-12 pr-6 py-4 outline-none focus:ring-2 focus:ring-blue-400 font-bold text-sm" onChange={(e) => setStudentSearch(e.target.value)} />
              </div>
              <div className="flex-1 overflow-y-auto p-4 space-y-2">
                 {students
                  .filter(s => (s.status === 'active' || !s.status) && s.studentName?.toLowerCase().includes(studentSearch.toLowerCase()))
                  .map(s => {
                    const isAlreadyIn = routes.find(r => r.id === showStudentPicker)?.assignedStudents?.some(as => as.id === s.id);
                    return (
                      <button key={s.id} onClick={() => addStudentToRoute(showStudentPicker, s)} disabled={isAlreadyIn} className={`w-full p-5 rounded-3xl flex justify-between items-center transition-all border ${isAlreadyIn ? 'bg-slate-50 border-slate-100 opacity-50' : 'bg-white border-slate-100 hover:border-blue-500 hover:bg-blue-50 group shadow-sm'}`}>
                         <div className="text-left">
                            <p className="font-black text-xs uppercase text-slate-700">{s.studentName}</p>
                            <p className="text-[10px] font-bold text-slate-400 italic">{s.grade || 'CADE'}</p>
                            {!s.stopLat && <span className="text-[8px] font-black text-red-500 mt-1 block uppercase italic underline">⚠️ REQUIERE GPS</span>}
                         </div>
                         {isAlreadyIn ? <Info className="w-5 h-5 text-blue-500" /> : <Plus className={`w-5 h-5 ${primaryBlueText} opacity-0 group-hover:opacity-100`} />}
                      </button>
                    )
                  })}
              </div>
              <div className="p-8 border-t border-slate-100 bg-slate-50"><button onClick={() => setShowStudentPicker(null)} className={`w-full py-4 ${primaryBlue} text-white font-black rounded-2xl text-xs uppercase shadow-lg shadow-blue-100`}>FINALIZAR SELECCIÓN</button></div>
           </div>
        </div>
      )}

      {/* POPUP MAPA INDIVIDUAL */}
      {studentMapData && (
        <div className="fixed inset-0 z-[5000] bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
           <div className="bg-white w-full max-w-sm rounded-[2.5rem] shadow-2xl overflow-hidden border-4 border-white">
              <div className={`p-6 ${primaryBlue} text-white flex justify-between items-center`}>
                 <div className="flex items-center gap-2"><MapPin className="w-4 h-4 text-white" /><p className="text-[10px] font-black uppercase tracking-widest italic font-bold">POSICIÓN GPS</p></div>
                 <button onClick={() => setStudentMapData(null)} className="w-8 h-8 flex items-center justify-center bg-white/10 rounded-full hover:bg-white/20"><X className="w-4 h-4" /></button>
              </div>
              <div className="h-64 bg-slate-100">
                 {studentMapData.stopLat && L ? (
                   <MapContainer center={[studentMapData.stopLat, studentMapData.stopLng]} zoom={15} style={{ height: '100%', width: '100%' }}>
                      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
                      <Marker position={[studentMapData.stopLat, studentMapData.stopLng]} />
                   </MapContainer>
                 ) : (
                   <div className="flex flex-col items-center justify-center h-full text-slate-300 p-8 text-center italic font-bold text-xs"><AlertCircle className="w-10 h-10 mb-2 opacity-20" />SIN UBICACIÓN</div>
                 )}
              </div>
              <div className="p-8 text-center bg-white border-t border-slate-100">
                 <p className="font-black text-slate-800 uppercase text-sm mb-1">{studentMapData.studentName}</p>
                 <button onClick={() => setStudentMapData(null)} className={`mt-8 w-full py-4 ${primaryBlue} text-white font-black rounded-2xl text-[10px] uppercase shadow-xl shadow-blue-100`}>CERRAR VISTA</button>
              </div>
           </div>
        </div>
      )}

    </DashboardLayout>
  );
}
