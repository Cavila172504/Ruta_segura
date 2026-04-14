"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc, setDoc, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const RepresentativesPage = () => {
  const [representatives, setRepresentatives] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Activos');
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
    unitCode: 'CAD31'
  });

  const SCHOOL_CODE = 'CAD31';

  useEffect(() => {
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
  }, []);

  const updateRepStatus = async (id, newStatus) => {
    try {
      const repRef = doc(db, 'companies', SCHOOL_CODE, 'students', id);
      await updateDoc(repRef, { status: newStatus });
    } catch (error) {
      console.error("Error updating status:", error);
      alert("Hubo un error al actualizar el estado.");
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
      alert("✅ Eliminado con éxito.");
    } catch (error) {
      console.error("Error al eliminar:", error);
      alert("❌ Error: No se pudo eliminar.");
    }
  };

  const [editFormData, setEditFormData] = useState(null);

  const openEditModal = (rep) => {
    setSelectedRep(rep);
    setEditFormData({ ...rep }); // Copiamos los datos para editarlos
    setShowEditModal(true);
  };



  const handleEditSave = async () => {
    if (!editFormData) return;
    try {
      const repRef = doc(db, 'companies', SCHOOL_CODE, 'students', editFormData.id);
      await setDoc(repRef, editFormData, { merge: true });
      setShowEditModal(false);
      alert("Cambios guardados con éxito.");
    } catch (error) {
      console.error("Error saving:", error);
      alert("Error al guardar los cambios.");
    }
  };

  const handleAddSubmit = async (e) => {
    e.preventDefault();
    try {
      const repsRef = collection(db, 'companies', SCHOOL_CODE, 'students');
      
      const newDoc = {
        ...formData,
        status: 'active',
        createdAt: serverTimestamp(),
      };
      
      await addDoc(repsRef, newDoc);
      setShowAddModal(false);
      setFormData({
        cedulaPadre: '',
        parentName: '',
        parentEmail: '',
        studentName: '',
        grade: 'Inicial 1',
        serviceType: 'Completo (Ida y Retorno)',
        unitCode: 'CAD31'
      });
      alert('Registro creado exitosamente.');
    } catch (error) {
      console.error("Error adding student:", error);
      alert('Error al crear registro.');
    }
  };

  const filteredReps = representatives.filter(rep => {
    const matchesSearch = 
      (rep.studentName || rep.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (rep.parentName || rep.lastName || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      rep.idNumber?.includes(searchTerm) ||
      rep.email?.toLowerCase().includes(searchTerm.toLowerCase());
    
    if (activeTab === 'Activos') return matchesSearch && (rep.status === 'active' || !rep.status);
    if (activeTab === 'No Activos') return matchesSearch && rep.status === 'pending';
    return matchesSearch;
  });



  return (
    <DashboardLayout title="Gestión de Representantes">
      <div className="mb-8 flex justify-between items-center">
        <h1 className="text-2xl font-bold text-slate-400 uppercase tracking-tight">REPRESENTANTES</h1>
        <button 
          onClick={() => setShowAddModal(true)}
          className="bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-2 rounded font-bold flex items-center gap-2 transition-all shadow-lg active:scale-95"
        >
          <span className="material-symbols-outlined">add</span>
          NUEVO
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200 mb-6">
        {['Activos', 'No Activos', 'Todos'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-10 py-4 text-sm font-bold transition-all border-b-2 ${
              activeTab === tab 
                ? 'border-primary text-primary bg-primary/5' 
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Search Bar */}
      <div className="relative mb-6 max-w-md">
        <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined">search</span>
        <input 
          type="text"
          placeholder="Buscar"
          className="w-full pl-10 pr-4 py-2 bg-slate-50 border-b border-slate-200 outline-none focus:border-primary transition-all text-sm"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      {/* Table */}
      <div className="bg-white rounded-sm shadow-sm overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-100">
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">ID</th>
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Identificación</th>
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Representante</th>
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Estudiante</th>
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Servicio</th>
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Estado</th>
              <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {loading ? (
              <tr><td colSpan="7" className="py-10 text-center text-slate-400">Cargando datos...</td></tr>
            ) : filteredReps.length === 0 ? (
              <tr><td colSpan="7" className="py-10 text-center text-slate-400">No hay registros con los criterios seleccionados.</td></tr>
            ) : filteredReps.map((rep, idx) => (
              <tr key={rep.id} className="hover:bg-slate-50/50 transition-colors">
                <td className="px-6 py-4 text-center text-xs text-slate-500">{idx + 1}</td>
                <td className="px-6 py-4 text-center text-xs text-slate-700 font-medium">{rep.cedulaPadre || rep.idNumber || 'S/N'}</td>
                <td className="px-6 py-4 text-center text-xs text-slate-700 font-bold uppercase">{rep.parentName || rep.name || '---'}</td>
                <td className="px-6 py-4 text-center text-xs text-slate-700 uppercase">{rep.studentName || '---'}</td>
                <td className="px-6 py-4 text-center text-xs text-slate-500">{rep.serviceType || '---'}</td>
                <td className="px-6 py-4 text-center">
                  {rep.status === 'active' ? (
                    <span className="bg-emerald-100 text-emerald-700 px-3 py-1 rounded-full text-[10px] font-black uppercase">ACEPTADO</span>
                  ) : (
                    <button 
                      onClick={() => updateRepStatus(rep.id, 'active')}
                      className="bg-[#FFF4D1] text-[#B78B01] hover:bg-[#FFE8A3] px-4 py-1.5 rounded-full text-[11px] font-black uppercase transition-all shadow-sm border border-[#F5E1A4] tracking-tight"
                    >
                      ACEPTAR
                    </button>
                  )}
                </td>
                <td className="px-6 py-4 text-center">
                  <div className="flex justify-center gap-2">
                    <button onClick={() => openEditModal(rep)} className="text-slate-400 hover:text-primary transition-colors">
                      <span className="material-symbols-outlined text-lg">edit_note</span>
                    </button>
                    <button 
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        console.log("Solicitando borrado de:", rep.id);
                        handleDelete(rep.id, rep.studentName);
                      }} 
                      className="text-slate-400 hover:text-red-500 transition-all p-2 cursor-pointer relative z-10"
                      title="Eliminar Estudiante"
                    >
                      <span className="material-symbols-outlined text-lg pointer-events-none">delete</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        
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
                  </div>
                  <div className="pt-4 flex justify-between items-center">
                      <button 
                        onClick={() => updateRepStatus(editFormData.id, editFormData.status === 'active' ? 'pending' : 'active')}
                        className={`px-4 py-2 rounded text-white text-[10px] font-bold ${editFormData?.status === 'active' ? 'bg-amber-500' : 'bg-emerald-500'}`}
                      >
                        {editFormData?.status === 'active' ? 'DESACTIVAR ACCOUNT' : 'ACTIVAR CUENTA'}
                      </button>
                      <button 
                        onClick={handleEditSave}
                        className="bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-2 rounded text-[10px] font-bold flex items-center gap-1 transition-all active:scale-95"
                      >
                        <span className="material-symbols-outlined text-xs">save</span> GUARDAR
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
                    Estás a punto de borrar permanentemente a <span className="font-bold text-slate-800">"{deletingRep.name}"</span>.<br/>Esta acción no se puede deshacer.
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

      {/* Add New Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white rounded-lg shadow-2xl w-full max-w-4xl overflow-hidden animate-in fade-in zoom-in duration-200">
            <div className="p-6 flex justify-between items-center border-b bg-slate-50">
               <div>
                  <h2 className="text-sm font-black text-slate-800 uppercase tracking-tighter">REGISTRAR NUEVA FAMILIA</h2>
                  <p className="text-[10px] text-slate-400 font-bold uppercase">Administración de Rutas Escolares</p>
               </div>
               <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-red-500 transition-colors">
                  <span className="material-symbols-outlined">close</span>
               </button>
            </div>

            <form onSubmit={handleAddSubmit} className="p-8">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                {/* REPRESENTANTE SECTION */}
                <div className="space-y-6">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="w-8 h-8 rounded bg-primary/10 text-primary flex items-center justify-center font-bold text-xs">01</span>
                    <h3 className="text-[11px] font-black text-slate-700 uppercase tracking-wider">DATOS DEL REPRESENTANTE</h3>
                  </div>
                  
                  <div className="space-y-4">
                    <div className="space-y-1">
                      <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Cédula Identidad</label>
                      <input 
                        required
                        type="text" 
                        placeholder="Ej. 1712345678"
                        className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-primary focus:bg-white transition-all"
                        value={formData.cedulaPadre}
                        onChange={(e) => setFormData({...formData, cedulaPadre: e.target.value})}
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Nombres Completos</label>
                      <input 
                        required
                        type="text" 
                        placeholder="Ej. Juan Pérez"
                        className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-primary focus:bg-white transition-all"
                        value={formData.parentName}
                        onChange={(e) => setFormData({...formData, parentName: e.target.value})}
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Correo Electrónico</label>
                      <input 
                        required
                        type="email" 
                        placeholder="representante@ejemplo.com"
                        className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-primary focus:bg-white transition-all"
                        value={formData.parentEmail}
                        onChange={(e) => setFormData({...formData, parentEmail: e.target.value})}
                      />
                    </div>
                  </div>
                </div>

                {/* ESTUDIANTE SECTION */}
                <div className="space-y-6">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="w-8 h-8 rounded bg-emerald-500/10 text-emerald-600 flex items-center justify-center font-bold text-xs">02</span>
                    <h3 className="text-[11px] font-black text-slate-700 uppercase tracking-wider">DATOS DEL ESTUDIANTE</h3>
                  </div>

                  <div className="space-y-4">
                    <div className="space-y-1">
                      <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Nombre del Alumno</label>
                      <input 
                        required
                        type="text" 
                        placeholder="Ej. Mateo Pérez"
                        className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-emerald-500 focus:bg-white transition-all"
                        value={formData.studentName}
                        onChange={(e) => setFormData({...formData, studentName: e.target.value})}
                      />
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-1">
                        <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Grado / Curso</label>
                        <select 
                          className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-emerald-500 focus:bg-white transition-all"
                          value={formData.grade}
                          onChange={(e) => setFormData({...formData, grade: e.target.value})}
                        >
                          <option>Inicial 1</option>
                          <option>Inicial 2</option>
                          <option>Primero de Básica</option>
                          <option>Segundo de Básica</option>
                          <option>Octavo de Básica</option>
                          <option>Primero de Bachillerato</option>
                        </select>
                      </div>
                      <div className="space-y-1">
                        <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Unidad/Bus</label>
                        <input 
                          type="text" 
                          placeholder="CAD31"
                          className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-emerald-500 focus:bg-white transition-all"
                          value={formData.unitCode}
                          onChange={(e) => setFormData({...formData, unitCode: e.target.value.toUpperCase()})}
                        />
                      </div>
                    </div>

                    <div className="space-y-1">
                      <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest px-1">Tipo de Servicio</label>
                      <select 
                        className="w-full text-xs p-3 bg-slate-50 border border-slate-200 rounded-md outline-none focus:border-emerald-500 focus:bg-white transition-all text-emerald-700 font-bold"
                        value={formData.serviceType}
                        onChange={(e) => setFormData({...formData, serviceType: e.target.value})}
                      >
                        <option>Completo (Ida y Retorno)</option>
                        <option>Solo Entrada (Mañana)</option>
                        <option>Solo Salida (Tarde)</option>
                        <option>Combinado / Especial</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-12 flex justify-end gap-3 border-t pt-6 bg-white">
                <button 
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-8 py-3 text-[11px] font-black text-slate-400 hover:text-slate-600 transition-all uppercase tracking-widest"
                >
                  Cancelar
                </button>
                <button 
                  type="submit"
                  className="px-10 py-3 bg-emerald-500 hover:bg-emerald-600 active:scale-95 text-white rounded-md text-[11px] font-black shadow-lg shadow-emerald-500/20 transition-all uppercase tracking-widest"
                >
                  Guardar Registro
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <footer className="mt-10 text-[10px] font-medium text-slate-400">
         2026 - Ruta Segura Cavila95
      </footer>
    </DashboardLayout>
  );
};

export default RepresentativesPage;
