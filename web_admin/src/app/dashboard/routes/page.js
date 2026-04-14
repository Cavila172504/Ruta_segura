'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, onSnapshot, query, addDoc, serverTimestamp, doc, updateDoc, deleteDoc, orderBy } from 'firebase/firestore';
import DashboardLayout from '@/components/layout/DashboardLayout';
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

  const SCHOOL_CODE = 'CAD31';
  const days = ['L', 'M', 'MI', 'J', 'V', 'S', 'D'];
  
  // Colores Institucionales Suaves
  const primaryBlue = 'bg-[#4361ee]'; // Azul suave institucional
  const primaryBlueText = 'text-[#4361ee]';

  useEffect(() => {
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
  }, []);

  const handleSaveNewRoute = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    try {
      await addDoc(collection(db, 'companies', SCHOOL_CODE, 'routes'), {
        name: formData.get('name') || 'SIN NOMBRE',
        shift: formData.get('shift') || 'MATUTINA',
        entryDriver: formData.get('driver') || '',
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
      <div className="max-w-[1500px] mx-auto space-y-6 pb-20">
        
        {/* CABECERA (Azul Suave) */}
        <div className="bg-white p-6 rounded-[2.5rem] shadow-sm border border-slate-100 flex justify-between items-center">
           <button onClick={() => setShowCreate(!showCreate)} className={`flex items-center gap-2 px-8 py-4 ${primaryBlue} text-white rounded-2xl font-black text-xs hover:brightness-110 transition-all shadow-lg shadow-blue-200`}>
              {showCreate ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
              {showCreate ? 'CANCELAR' : 'NUEVA RUTA TÁCTICA'}
           </button>
           <div className="text-right">
              <p className="text-[10px] font-black text-slate-400 uppercase italic tracking-widest">RutaSegura Global</p>
              <p className={`text-xl font-black ${primaryBlueText} tracking-tighter`}>PANEL GESTIÓN</p>
           </div>
        </div>

        {/* CREACIÓN */}
        {showCreate && (
          <form onSubmit={handleSaveNewRoute} className="bg-white p-10 rounded-[3rem] shadow-2xl border border-blue-50 animate-in slide-in-from-top duration-300">
             <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-2 block tracking-widest">Nombre de Ruta</label>
                   <input name="name" placeholder="Ej: RUTA 1" className="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 outline-none focus:ring-2 focus:ring-blue-400 font-bold" />
                </div>
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-2 block tracking-widest">Jornada</label>
                   <select name="shift" className="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 outline-none font-bold">
                      <option>MATUTINA</option><option>VESPERTINA</option><option>NOCTURNA</option>
                   </select>
                </div>
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-2 block tracking-widest">Conductor</label>
                   <select name="driver" className="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 outline-none font-bold">
                      <option value="">Seleccionar...</option>
                      {drivers.map(d => <option key={d.id} value={d.name || `${d.names} ${d.lastNames}`}>{d.name || `${d.names} ${d.lastNames}`}</option>)}
                   </select>
                </div>
                <div>
                   <label className="text-[10px] font-black text-slate-400 uppercase italic mb-2 block tracking-widest">Placa / Unidad</label>
                   <input name="unit" placeholder="Ej: P-10" className="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 outline-none font-bold" />
                </div>
             </div>
             <div className="flex justify-end gap-4"><button type="submit" className={`px-12 py-4 ${primaryBlue} text-white font-black rounded-2xl shadow-xl shadow-blue-100 hover:scale-105 active:scale-95 transition-all`}>GUARDAR RUTA</button></div>
          </form>
        )}

        {/* LISTADO DE RUTAS */}
        <div className="space-y-6">
           {routes.map(route => (
             <div key={route.id} className="bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden flex flex-col">
                
                {/* HEAD DE RUTA (CON CONDUCTOR Y PLACA) */}
                <div className="p-8 flex flex-wrap items-center justify-between gap-8">
                   <div className="flex items-center gap-6">
                      <div className={`w-16 h-16 ${primaryBlue} bg-opacity-10 rounded-2xl flex items-center justify-center`}><Truck className={`w-8 h-8 ${primaryBlueText}`} /></div>
                      <div>
                         <h3 className="text-2xl font-black text-slate-800 uppercase tracking-tighter leading-none mb-2">{route.name}</h3>
                         <div className="flex gap-4">
                            <span className={`text-[10px] font-black ${primaryBlue} text-white px-3 py-1 rounded-lg italic`}>{route.shift}</span>
                            <span className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase"><User className="w-3 h-3 text-blue-400" /> {route.entryDriver || 'PENDIENTE'}</span>
                            <span className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase"><CreditCard className="w-3 h-3 text-blue-400" /> PLACA: {route.entryUnit || 'S/N'}</span>
                         </div>
                      </div>
                   </div>

                   <div className="flex gap-4">
                      <button 
                        onClick={() => setExpandedRoute(expandedRoute === route.id ? null : route.id)}
                        className={`flex items-center gap-2 px-8 py-4 rounded-2xl font-black text-xs transition-all ${expandedRoute === route.id ? 'bg-amber-100 text-amber-700' : 'bg-slate-50 text-slate-600 hover:bg-blue-50 hover:text-blue-700'}`}
                      >
                         {expandedRoute === route.id ? 'CERRAR PANEL' : 'GESTIONAR PASAJEROS'}
                         {expandedRoute === route.id ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                      </button>
                      <button onClick={() => deleteDoc(doc(db, 'companies', SCHOOL_CODE, 'routes', route.id))} className="p-4 text-slate-200 hover:text-red-500 transition-all"><Trash2 className="w-6 h-6" /></button>
                   </div>
                </div>

                {/* CUERPO TÁCTICO */}
                {expandedRoute === route.id && (
                  <div className="p-8 bg-slate-50 border-t border-slate-100 space-y-6 animate-in slide-in-from-top duration-300">
                     
                     <div className="flex flex-wrap justify-between items-center gap-6">
                        <button onClick={() => setShowStudentPicker(route.id)} className={`flex items-center gap-3 px-10 py-4 ${primaryBlue} text-white rounded-2xl font-black text-xs hover:scale-105 transition-all shadow-xl shadow-blue-100`}>
                           <Plus className="w-4 h-4 text-white" /> AGREGAR ESTUDIANTES A RUTA
                        </button>
                        
                        {/* LEYENDA TÁCTICA */}
                        <div className="flex flex-wrap items-center gap-6 bg-white px-8 py-4 rounded-3xl border border-slate-200 shadow-sm">
                           <div className="flex items-center gap-2"><span className="text-[10px] font-black text-slate-400">SIGNIFICADOS:</span></div>
                           <div className="flex items-center gap-2"><div className="w-4 py-1 bg-emerald-500 text-white flex items-center justify-center rounded text-[8px] font-black">E</div><span className="text-[10px] font-bold text-slate-500">ENTRADA (Mñn)</span></div>
                           <div className="flex items-center gap-2"><div className="w-4 py-1 bg-emerald-500 text-white flex items-center justify-center rounded text-[8px] font-black">S</div><span className="text-[10px] font-bold text-slate-500">SALIDA (Tde)</span></div>
                           <div className="w-px h-8 bg-slate-100 mx-2"></div>
                           <div className="flex items-center gap-2"><div className="w-2 h-2 bg-emerald-500 rounded-full"></div><span className="text-[10px] font-bold text-slate-500 uppercase">Asiste</span></div>
                           <div className="flex items-center gap-2"><div className="w-2 h-2 bg-slate-200 rounded-full"></div><span className="text-[10px] font-bold text-slate-500 uppercase">Posible</span></div>
                           <div className="flex items-center gap-2"><div className="w-2 h-2 bg-red-500 rounded-full"></div><span className="text-[10px] font-bold text-slate-500 uppercase">No Asiste</span></div>
                        </div>
                     </div>

                     <div className="bg-white rounded-[2.5rem] shadow-xl border border-slate-200 overflow-hidden">
                        <table className="w-full text-left">
                           <thead className={`${primaryBlue} text-white`}>
                              <tr className="text-[10px] font-black uppercase tracking-widest italic">
                                 <th className="px-8 py-6">#</th>
                                 <th className="px-8 py-6">Estudiante</th>
                                 <th className="px-8 py-6">Tipo Servicio</th>
                                 <th className="px-8 py-6 text-center italic">Mapa</th>
                                 {days.map(d => <th key={d} className="px-1 py-6 text-center border-l border-white/10">{d}</th>)}
                                 <th className="px-8 py-6 text-center text-red-200">Quitar</th>
                              </tr>
                           </thead>
                           <tbody className="divide-y divide-slate-50">
                              {route.assignedStudents?.map((s, idx) => (
                                <tr key={s.id} className="hover:bg-blue-50/30 transition-all">
                                   <td className="px-8 py-5 text-xs font-bold text-slate-300">{idx + 1}</td>
                                   <td className="px-8 py-5">
                                      <p className="font-black text-xs uppercase text-slate-700">{s.studentName}</p>
                                      <p className="text-[9px] font-bold text-slate-400 italic font-medium">{s.grade || 'CADE'}</p>
                                   </td>
                                   <td className="px-8 py-5">
                                      <select 
                                        value={s.serviceType || 'COMPLETO'}
                                        onChange={(e) => updateStudentService(route.id, s.id, e.target.value)}
                                        className="bg-slate-50 border border-slate-100 rounded-lg px-2 py-1.5 text-[10px] font-black text-slate-500 uppercase outline-none focus:ring-1 focus:ring-blue-400"
                                      >
                                         <option>COMPLETO</option><option>SOLO IDA</option><option>SOLO RETORNO</option>
                                      </select>
                                   </td>
                                   <td className="px-8 py-5 text-center">
                                      <button onClick={() => setStudentMapData(s)} className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center hover:bg-blue-100 transition-all mx-auto"><MapPin className="w-4 h-4" /></button>
                                   </td>
                                   {days.map(d => {
                                      const m = s.matrix?.[d] || { entrance: 'confirmed', exit: 'confirmed' };
                                      return (
                                        <td key={d} className="px-1 py-5 border-l border-slate-50">
                                           <div className="flex flex-col gap-1 items-center">
                                              <button onClick={() => updateMatrixCell(route.id, s.id, d, 'entrance', m.entrance)} className={`w-8 py-1.5 rounded-lg text-[8px] font-black transition-all ${m.entrance === 'confirmed' ? 'bg-emerald-500 text-white' : m.entrance === 'maybe' ? 'bg-slate-200 text-slate-400' : 'bg-red-500 text-white'}`}>E</button>
                                              <button onClick={() => updateMatrixCell(route.id, s.id, d, 'exit', m.exit)} className={`w-8 py-1.5 rounded-lg text-[8px] font-black transition-all ${m.exit === 'confirmed' ? 'bg-emerald-500 text-white' : m.exit === 'maybe' ? 'bg-slate-200 text-slate-400' : 'bg-red-500 text-white'}`}>S</button>
                                           </div>
                                        </td>
                                      )
                                   })}
                                   <td className="px-8 py-5 text-center">
                                      <button onClick={() => removeStudentFromRoute(route.id, s.id)} className="text-slate-200 hover:text-red-300 transition-all"><X className="w-5 h-5" /></button>
                                   </td>
                                </tr>
                              ))}
                              {!route.assignedStudents?.length && (
                                <tr><td colSpan={11} className="py-24 text-center text-[10px] font-black text-slate-300 uppercase italic tracking-widest animate-pulse">Haz clic en "AGREGAR ESTUDIANTES" para iniciar la hoja de ruta</td></tr>
                              )}
                           </tbody>
                        </table>
                        <div className="p-8 bg-slate-50 border-t border-slate-100 flex justify-end">
                           <button 
                             onClick={() => handleSync(route.id)} 
                             className={`flex items-center gap-3 px-12 py-5 text-white font-black rounded-[2rem] text-xs uppercase shadow-2xl transition-all hover:scale-105 active:scale-95 ${syncStatus[route.id] === 'synced' ? 'bg-slate-400 shadow-slate-200' : 'bg-emerald-500 shadow-emerald-200'}`}
                           >
                              <Save className="w-5 h-5" /> 
                              {syncStatus[route.id] === 'synced' ? '¡SINCRO EXITOSA!' : 'ACTUALIZAR Y SINCRONIZAR'}
                           </button>
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
                  .filter(s => s.studentName?.toLowerCase().includes(studentSearch.toLowerCase()))
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
