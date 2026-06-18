"use client";
import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc, setDoc, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';

const normalizeCedula = (value) => (value || '').replace(/\D/g, '');

const RepresentativesPage = () => {
  const [representatives, setRepresentatives] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Aprobados');
  const [searchTerm, setSearchTerm] = useState('');
  const [showEditModal, setShowEditModal] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deletingRep, setDeletingRep] = useState(null);
  const [selectedRep, setSelectedRep] = useState(null);
  
  // Nuevo estado para el formulario de registro
  const [formData, setFormData] = useState({
    cedulaPadre: '',
    parentName: '',
    parentEmail: '',
    studentName: '',
    grade: 'Inicial 1',
    serviceType: 'Completo (Ida y Retorno)',
    unitCode: ''
  });

  const { profile, loading: authLoading, SCHOOL_CODE } = useAuth();
  const toast = useToast();

  // Sincronizar unitCode del formulario con el perfil
  useEffect(() => {
    if (SCHOOL_CODE && formData.unitCode !== SCHOOL_CODE) {
      const timer = setTimeout(() => {
        setFormData(prev => ({ ...prev, unitCode: SCHOOL_CODE }));
      }, 0);
      return () => clearTimeout(timer);
    }
  }, [SCHOOL_CODE]); // Mantener tamaño constante para evitar error de hooks con Fast Refresh

  useEffect(() => {
    if (authLoading || !SCHOOL_CODE) return;

    // Usamos la colección de representantes/padres
    const repsRef = collection(db, 'companies', SCHOOL_CODE, 'students');
    const q = query(repsRef, orderBy('createdAt', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setRepresentatives(list);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [SCHOOL_CODE, authLoading]);

  const updateRepStatus = async (id, newStatus) => {
    try {
      const repRef = doc(db, 'companies', SCHOOL_CODE, 'students', id);
      await updateDoc(repRef, { 
        status: newStatus,
        approvedAt: serverTimestamp()
      });
    } catch (error) {
      console.error("Error updating status:", error);
      toast.error("Hubo un error al actualizar el estado.");
    }
  };

  const handleDelete = (id, name) => {
    setDeletingRep({ id, name });
    setShowDeleteModal(true);
  };

  const confirmDelete = async () => {
    if (!deletingRep) return;
    try {
      const repRef = doc(db, 'companies', SCHOOL_CODE, 'students', deletingRep.id);
      await deleteDoc(repRef);
      setShowDeleteModal(false);
      setDeletingRep(null);
      toast.success("Eliminado con éxito.");
    } catch (error) {
      console.error("Error al eliminar:", error);
      toast.error("No se pudo eliminar.");
    }
  };

  const [editFormData, setEditFormData] = useState(null);

  const openEditModal = (rep) => {
    setSelectedRep(rep);
    setEditFormData({ ...rep }); 
    setShowEditModal(true);
  };

  const handleEditSave = async () => {
    if (!editFormData) return;
    try {
      const repRef = doc(db, 'companies', SCHOOL_CODE, 'students', editFormData.id);
      await setDoc(repRef, {
        ...editFormData,
        cedulaPadreNorm: normalizeCedula(editFormData.cedulaPadre || editFormData.idNumber),
      }, { merge: true });
      setShowEditModal(false);
      toast.success("Cambios guardados con éxito.");
    } catch (error) {
      console.error("Error saving:", error);
      toast.error("Error al guardar los cambios.");
    }
  };

  const handleAddSubmit = async (e) => {
    e.preventDefault();
    try {
      const repsRef = collection(db, 'companies', SCHOOL_CODE, 'students');
      
      const newDoc = {
        ...formData,
        cedulaPadreNorm: normalizeCedula(formData.cedulaPadre),
        parentId: '',
        status: 'pending',
        createdAt: serverTimestamp(),
      };
      
      await addDoc(repsRef, newDoc);
      setShowAddModal(false);
      setFormData({
        unitCode: SCHOOL_CODE
      });
      toast.success('Registro creado exitosamente.');
    } catch (error) {
      console.error("Error adding student:", error);
      toast.error('Error al crear registro.');
    }
  };

  const filteredReps = representatives.filter(rep => {
    const matchesSearch = 
      (rep.studentName || rep.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (rep.parentName || rep.lastName || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      rep.idNumber?.includes(searchTerm) ||
      rep.email?.toLowerCase().includes(searchTerm.toLowerCase());
    
    if (activeTab === 'Alumnos aprobados') return matchesSearch && rep.status === 'active';
    if (activeTab === 'Alumnos Inscritos') return matchesSearch && (rep.status === 'pending' || !rep.status);
    return matchesSearch;
  });



  return (
    <DashboardLayout title="Gestión de Representantes">
      <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center bg-white p-4 sm:p-6 rounded-2xl shadow-sm border border-slate-100 gap-4">
        <h1 className="text-2xl font-black text-slate-800 uppercase tracking-tighter italic">REPRESENTANTES</h1>
        {profile?.role !== 'viewer' && (
          <div className="w-full sm:w-auto justify-center bg-blue-50 text-blue-600 px-5 py-2 rounded font-bold flex items-center gap-2 shadow-sm text-xs border border-blue-100">
            <span className="material-symbols-outlined text-sm">info</span>
            LOS PADRES DEBEN REGISTRARSE DESDE LA APP
          </div>
        )}
      </div>

      <div className="flex border-b border-slate-200 mb-6 overflow-x-auto hide-scrollbar">
        {['Alumnos aprobados', 'Alumnos Inscritos', 'Todos'].map((tab) => {
          const statusKey = tab === 'Alumnos aprobados' ? 'active' : (tab === 'Alumnos Inscritos' ? 'pending' : null);
          const count = tab === 'Alumnos Inscritos' 
            ? representatives.filter(r => !r.status || r.status === 'pending').length 
            : null;
            
          return (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 sm:px-6 py-3 min-w-fit text-sm font-black transition-all border-b-4 flex items-center gap-2 ${
                activeTab === tab 
                  ? 'border-primary text-primary bg-primary/5' 
                  : 'border-transparent text-slate-400 hover:text-slate-600'
              }`}
            >
              {tab}
              {count > 0 && (
                <span className="bg-red-500 text-white text-[10px] font-black px-2 py-0.5 rounded shadow-sm">
                  {count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Search Bar */}
      <div className="relative mb-6 mx-auto w-full max-w-md md:max-w-xl md:mx-0">
        <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-lg">search</span>
        <input 
          type="text"
          placeholder="Buscar estudiante o padre..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all text-sm font-bold shadow-sm"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-md border border-slate-100 overflow-hidden text-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left min-w-[800px]">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-100">
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center w-12">N°</th>
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Identificac.</th>
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-left">Representante</th>
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-left">Estudiante</th>
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Servicio</th>
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Conductor</th>
                <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Estado</th>
                {profile?.role !== 'viewer' && <th className="px-4 py-3 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Opciones</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {loading ? (
                <tr><td colSpan="8" className="py-6 text-center text-slate-400 text-sm">Cargando datos...</td></tr>
              ) : filteredReps.length === 0 ? (
                <tr><td colSpan="8" className="py-6 text-center text-slate-400 text-sm">No hay registros con los criterios.</td></tr>
              ) : filteredReps.map((rep, idx) => (
                <tr key={rep.id} className="hover:bg-slate-50/80 transition-all group">
                  <td className="px-4 py-3 text-center text-xs font-bold text-slate-400">{idx + 1}</td>
                  <td className="px-4 py-3 text-center text-xs text-slate-700 font-bold">{rep.cedulaPadre || rep.idNumber || 'S/N'}</td>
                  <td className="px-4 py-3 text-left">
                     <p className="text-xs font-black text-slate-800 uppercase leading-tight">{rep.parentName || rep.name || '---'}</p>
                     <p className="text-[10px] font-bold text-slate-400 italic">{rep.email || 'SIN EMAIL'}</p>
                  </td>
                  <td className="px-4 py-3 text-left text-xs md:text-sm font-black text-primary uppercase">{rep.studentName || '---'}</td>
                  <td className="px-4 py-3 text-center text-[10px] font-bold text-slate-500 uppercase">{rep.serviceType || '---'}</td>
                  <td className="px-4 py-3 text-center">
                    {rep.driverId ? (
                      <span className="bg-blue-50 text-blue-700 border border-blue-100 px-2 py-1 rounded text-[9px] font-black uppercase">Asignado</span>
                    ) : (
                      <span className="bg-amber-50 text-amber-700 border border-amber-100 px-2 py-1 rounded text-[9px] font-black uppercase">Sin ruta</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {rep.status === 'active' ? (
                      <div className="flex flex-col items-center gap-1">
                        <span className="bg-emerald-50 text-emerald-600 border border-emerald-100 px-3 py-1 rounded text-[10px] font-black uppercase inline-block">APROBADO</span>
                        {rep.assignedRoute && (
                          <span className="text-[8px] font-bold text-slate-400 italic">Ruta: {rep.assignedRoute}</span>
                        )}
                      </div>
                    ) : (
                      profile?.role !== 'viewer' ? (
                        <button 
                          onClick={() => updateRepStatus(rep.id, 'active')}
                          className="bg-primary hover:bg-primary/90 text-white px-3 py-1.5 rounded text-[10px] font-black uppercase transition-all shadow-sm flex items-center gap-1 mx-auto active:scale-95"
                        >
                          <span className="material-symbols-outlined text-[14px]">verified</span>
                          ACEPTAR
                        </button>
                      ) : (
                        <span className="bg-slate-100 text-slate-400 px-3 py-1 rounded text-[10px] font-black uppercase">PENDIENTE</span>
                      )
                    )}
                  </td>
                  {profile?.role !== 'viewer' && (
                    <td className="px-4 py-3 text-center">
                      <div className="flex justify-center gap-2">
                        <button onClick={() => openEditModal(rep)} className="w-8 h-8 flex items-center justify-center bg-slate-50 text-slate-400 hover:bg-primary hover:text-white rounded transition-colors border border-slate-100 font-medium">
                          <span className="material-symbols-outlined text-sm">edit_note</span>
                        </button>
                        <button 
                          type="button"
                          onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            handleDelete(rep.id, rep.studentName);
                          }} 
                          className="w-8 h-8 flex items-center justify-center bg-slate-50 text-slate-400 hover:bg-red-500 hover:text-white rounded transition-colors border border-slate-100 font-medium"
                        >
                          <span className="material-symbols-outlined text-sm">delete</span>
                        </button>
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {/* Footer Pagination style */}
        <div className="px-6 py-4 bg-slate-50 flex justify-end items-center gap-6 text-[10px] font-bold text-slate-400 uppercase">
          <div className="flex items-center gap-2">
            Items per page: 
            <select className="bg-transparent outline-none">
              <option>10</option>
              <option>20</option>
            </select>
          </div>
          <div>0 of 0</div>
          <div className="flex gap-4">
               <span className="material-symbols-outlined text-sm cursor-pointer hover:text-slate-600">first_page</span>
               <span className="material-symbols-outlined text-sm cursor-pointer hover:text-slate-600">chevron_left</span>
               <span className="material-symbols-outlined text-sm cursor-pointer hover:text-slate-600">chevron_right</span>
               <span className="material-symbols-outlined text-sm cursor-pointer hover:text-slate-600">last_page</span>
          </div>
        </div>
      </div>

      {/* Edit Modal (The 3rd Image UI) */}
      {showEditModal && selectedRep && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-[2px]">
          <div className="bg-slate-50 rounded shadow-2xl w-full max-w-6xl max-h-[90vh] overflow-y-auto">
            <div className="p-4 flex justify-between items-center border-b bg-white">
               <h2 className="text-xs font-bold text-slate-400 uppercase tracking-widest">EDITAR REPRESENTANTE Y ALUMNOS</h2>
               <button onClick={() => setShowEditModal(false)} className="bg-emerald-500 text-white px-4 py-1 rounded text-[10px] font-bold">LISTA GENERAL</button>
            </div>

            <div className="p-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Parent Data Form */}
              <div className="lg:col-span-1">
                <div className="bg-black text-white text-center py-2 text-xs font-bold uppercase mb-4">Datos del Representante</div>
                <div className="bg-white p-6 shadow-sm rounded-sm space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                        <label className="text-[10px] text-slate-400">Cédula:</label>
                        <input 
                          type="text" 
                          value={editFormData?.cedulaPadre || editFormData?.idNumber || ''} 
                          onChange={(e) => setEditFormData({...editFormData, cedulaPadre: e.target.value})}
                          className="w-full text-xs p-2 border-b outline-none focus:border-primary" 
                        />
                    </div>
                    <div className="space-y-1">
                        <label className="text-[10px] text-slate-400">Representante:</label>
                        <input 
                          type="text" 
                          value={editFormData?.parentName || editFormData?.name || ''} 
                          onChange={(e) => setEditFormData({...editFormData, parentName: e.target.value})}
                          className="w-full text-xs p-2 border-b outline-none focus:border-primary" 
                        />
                    </div>
                    <div className="space-y-1">
                        <label className="text-[10px] text-slate-400">Email:</label>
                        <input 
                          type="text" 
                          value={editFormData?.parentEmail || editFormData?.email || ''} 
                          onChange={(e) => setEditFormData({...editFormData, parentEmail: e.target.value})}
                          className="w-full text-xs p-2 border-b outline-none focus:border-primary" 
                        />
                    </div>
                    <div className="space-y-1">
                        <label className="text-[10px] text-slate-400">Estudiante:</label>
                        <input 
                          type="text" 
                          value={editFormData?.studentName || ''} 
                          onChange={(e) => setEditFormData({...editFormData, studentName: e.target.value})}
                          className="w-full text-xs p-2 border-b outline-none focus:border-primary" 
                        />
                    </div>
                    <div className="space-y-1">
                        <label className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Estado Actual:</label>
                        <div className="pt-2">
                          {editFormData?.status === 'active' ? (
                            <span className="bg-emerald-50 text-emerald-600 border border-emerald-100 px-3 py-1 rounded text-[10px] font-black uppercase">ACTIVADO</span>
                          ) : (
                            <span className="bg-amber-50 text-amber-600 border border-amber-100 px-3 py-1 rounded text-[10px] font-black uppercase">PENDIENTE</span>
                          )}
                        </div>
                    </div>
                  </div>
                  <div className="pt-6 flex flex-col gap-3">
                      <button 
                        onClick={() => {
                          const newStatus = editFormData.status === 'active' ? 'pending' : 'active';
                          updateRepStatus(editFormData.id, newStatus);
                          setEditFormData({...editFormData, status: newStatus});
                        }}
                        className={`w-full py-3 rounded-xl text-white text-[10px] font-black uppercase tracking-widest transition-all shadow-md active:scale-95 ${editFormData?.status === 'active' ? 'bg-amber-500 hover:bg-amber-600 shadow-amber-100' : 'bg-emerald-500 hover:bg-emerald-600 shadow-emerald-100'}`}
                      >
                        {editFormData?.status === 'active' ? 'Revertir a Pendiente' : 'Aprobar Acceso'}
                      </button>
                      <button 
                        onClick={handleEditSave}
                        className="w-full py-3 bg-slate-900 hover:bg-black text-white rounded-xl text-[10px] font-black uppercase tracking-widest transition-all shadow-lg shadow-slate-200 flex items-center justify-center gap-2"
                      >
                        <span className="material-symbols-outlined text-sm">save</span> GUARDAR CAMBIOS
                      </button>
                  </div>
                </div>
              </div>

              {/* Students List for this parent */}
              <div className="lg:col-span-2">
                <div className="bg-black text-white text-center py-2 text-xs font-bold uppercase mb-4">Alumnos</div>
                <div className="bg-white shadow-sm rounded-sm">
                  <table className="w-full text-left text-[10px]">
                    <thead className="bg-slate-100">
                      <tr>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">ID</th>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">Alumno</th>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">Transporte</th>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">Paralelo</th>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">Estado</th>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">Ruta</th>
                        <th className="px-4 py-3 font-bold text-slate-600 uppercase">Editar</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 italic text-slate-400">
                      <tr>
                        <td colSpan="7" className="px-4 py-8 text-center text-slate-300">Cargando alumnos vinculados...</td>
                      </tr>
                    </tbody>
                  </table>
                  <div className="p-4 border-t bg-slate-50">
                    <button className="bg-emerald-500 text-white px-4 py-2 rounded text-[10px] font-bold flex items-center gap-1">
                      <span className="material-symbols-outlined text-xs">person_add</span> AGREGAR ALUMNO
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal (Custom alert) */}
      {showDeleteModal && deletingRep && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/80 backdrop-blur-md animate-in fade-in duration-200">
           <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in zoom-in duration-300">
              <div className="p-8 text-center">
                 <div className="w-20 h-20 bg-red-100 text-red-600 rounded-full flex items-center justify-center mx-auto mb-6">
                    <span className="material-symbols-outlined text-4xl">warning</span>
                 </div>
                 <h2 className="text-xl font-black text-slate-800 mb-2 uppercase tracking-tight">¿Eliminar Estudiante?</h2>
                 <p className="text-sm text-slate-500 mb-8 leading-relaxed">
                    Estás a punto de borrar permanentemente a <span className="font-bold text-slate-800">&quot;{deletingRep.name}&quot;</span>.<br/>Esta acción no se puede deshacer.
                 </p>
                 <div className="flex flex-col gap-3">
                    <button 
                       onClick={confirmDelete}
                       className="w-full py-4 bg-red-600 hover:bg-red-700 active:scale-95 text-white rounded-xl font-black text-xs uppercase tracking-widest transition-all shadow-lg shadow-red-200"
                    >
                       SÍ, ELIMINAR AHORA
                    </button>
                    <button 
                       onClick={() => { setShowDeleteModal(false); setDeletingRep(null); }}
                       className="w-full py-4 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-xl font-black text-xs uppercase tracking-widest transition-all"
                    >
                       No, cancelar
                    </button>
                 </div>
              </div>
           </div>
        </div>
      )}



      <footer className="mt-10 flex flex-col items-center gap-1 text-[10px] text-slate-400">
         <Link href="/politica-seguridad" className="hover:text-primary transition-colors">
           Política de seguridad y ubicación
         </Link>
         <span>© {new Date().getFullYear()} RutaSegura <span className="text-slate-300/50 ml-1">Cavila</span></span>
      </footer>
    </DashboardLayout>
  );
};

export default RepresentativesPage;
