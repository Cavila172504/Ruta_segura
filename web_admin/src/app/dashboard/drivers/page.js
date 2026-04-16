"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';

const DriversPage = () => {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [selectedDriverId, setSelectedDriverId] = useState(null);
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [driverToDelete, setDriverToDelete] = useState(null);

  const { profile, loading: authLoading, SCHOOL_CODE } = useAuth();

  // Form states refined
  const [formData, setFormData] = useState({
    docType: 'Cédula',
    idNumber: '',
    names: '',
    lastNames: '',
    email: '',
    address: '',
    cooperative: 'Colorado Express S.A'
  });

  useEffect(() => {
    if (authLoading || !SCHOOL_CODE) return;

    const driversRef = collection(db, 'companies', SCHOOL_CODE, 'drivers');
    const q = query(driversRef, orderBy('createdAt', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setDrivers(list);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [SCHOOL_CODE, authLoading]);

  const handleOpenCreateModal = () => {
    setFormData({ docType: 'Cédula', idNumber: '', names: '', lastNames: '', email: '', phoneCell: '', address: '', cooperative: 'Colorado Express S.A' });
    setIsEditMode(false);
    setShowModal(true);
  };

  const handleOpenEditModal = (driver) => {
    setFormData({
      docType: driver.docType || 'Cédula',
      idNumber: driver.idNumber || '',
      names: driver.names || '',
      lastNames: driver.lastNames || '',
      email: driver.email || '',
      phoneCell: driver.phoneCell || '',
      address: driver.address || '',
      cooperative: driver.cooperative || 'Colorado Express S.A'
    });
    setSelectedDriverId(driver.id);
    setIsEditMode(true);
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    try {
      const url = isEditMode ? `/api/drivers?id=${selectedDriverId}&unitCode=${SCHOOL_CODE}` : '/api/drivers';
      const method = isEditMode ? 'PATCH' : 'POST';

      const response = await fetch(url, {
        method: method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          name: `${formData.names} ${formData.lastNames}`,
          unitCode: SCHOOL_CODE,
          accessKey: formData.idNumber
        })
      });

      if (response.ok) {
        setShowModal(false);
        alert('Chofer Guardado Exitosamente');
      } else {
        const errData = await response.json();
        alert("Error: " + (errData.error || "No se pudo procesar la solicitud"));
      }
    } catch (error) {
      alert("Error de conexión");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteDriver = async () => {
    if (!driverToDelete) return;
    
    setIsDeleting(true);
    try {
      const response = await fetch(`/api/drivers?id=${driverToDelete.id}&unitCode=${SCHOOL_CODE}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        setShowDeleteModal(false);
        setDriverToDelete(null);
      } else {
        const err = await response.json();
        alert("Error del servidor: " + (err.error || "Desconocido"));
      }
    } catch (error) {
      alert("Error de conexión: " + error.message);
    } finally {
      setIsDeleting(false);
    }
  };

  const openDeleteModal = (driver) => {
    setDriverToDelete(driver);
    setShowDeleteModal(true);
  };

  const filteredDrivers = drivers.filter(d => 
    (d.names?.toLowerCase() + " " + d.lastNames?.toLowerCase()).includes(searchTerm.toLowerCase()) ||
    d.idNumber?.includes(searchTerm)
  );

  return (
    <DashboardLayout title="Gestión de Conductores">
      <section className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
        <div>
          <h2 className="text-3xl font-extrabold text-on-surface tracking-tight mb-2">Conductores</h2>
          <p className="text-on-surface-variant max-w-md">Administración del personal de transporte para {SCHOOL_CODE}.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[300px]">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-xl">search</span>
            <input 
              type="text"
              className="w-full pl-10 pr-4 py-2.5 bg-surface-container-lowest border-none rounded-xl text-sm outline-none shadow-sm"
              placeholder="Buscar conductor..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button 
            onClick={handleOpenCreateModal}
            className="flex items-center gap-2 bg-primary hover:bg-primary-container text-on-primary px-6 py-2.5 rounded-xl font-semibold text-sm transition-all shadow-lg shadow-primary/20"
          >
            <span className="material-symbols-outlined text-lg">person_add</span>
            Nuevo Conductor
          </button>
        </div>
      </section>

      <div className="bg-surface-container-lowest rounded-3xl overflow-hidden shadow-sm border border-outline-variant/10">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Nombre del Conductor</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Identificación (Clave)</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Cooperativa</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest text-center">Estado</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container">
              {filteredDrivers.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-6 py-10 text-center text-slate-400">Sin conductores registrados.</td>
                </tr>
              ) : (
                filteredDrivers.map((driver) => (
                  <tr key={driver.id} className="hover:bg-surface-bright transition-colors group">
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary text-sm font-bold uppercase">
                          {driver.names?.charAt(0)}{driver.lastNames?.charAt(0)}
                        </div>
                        <div>
                          <div className="font-bold text-on-surface text-sm uppercase">{driver.names} {driver.lastNames}</div>
                          <div className="text-[10px] text-slate-400">{driver.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <div className="text-slate-600 font-mono text-sm">{driver.idNumber}</div>
                    </td>
                    <td className="px-6 py-5">
                      <span className="text-xs font-bold text-slate-500">{driver.cooperative}</span>
                    </td>
                    <td className="px-6 py-5 text-center">
                      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase bg-emerald-50 text-emerald-600 border border-emerald-100">
                        Activo
                      </span>
                    </td>
                    <td className="px-6 py-5 text-right">
                      <div className="flex justify-end gap-3">
                         <button 
                          type="button"
                          onClick={(e) => { e.stopPropagation(); handleOpenEditModal(driver); }}
                          className="flex items-center gap-1 bg-slate-50 hover:bg-primary/10 text-slate-400 hover:text-primary px-3 py-2 rounded-xl transition-all border border-slate-100"
                        >
                          <span className="material-symbols-outlined text-sm">edit</span>
                          <span className="text-[10px] font-bold tracking-widest uppercase">Editar</span>
                        </button>
                        
                        <button 
                          type="button"
                          onClick={(e) => { e.stopPropagation(); openDeleteModal(driver); }}
                          className="flex items-center gap-1 bg-slate-50 hover:bg-error/10 text-slate-400 hover:text-error px-3 py-2 rounded-xl transition-all border border-slate-100"
                        >
                          <span className="material-symbols-outlined text-sm">delete</span>
                          <span className="text-[10px] font-bold tracking-widest uppercase">Eliminar</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-surface rounded-[40px] shadow-2xl max-w-4xl w-full overflow-hidden flex flex-col animate-in fade-in slide-in-from-bottom-4 duration-300">
            <div className="bg-primary p-10 flex justify-between items-center">
              <div>
                <h3 className="text-2xl font-black text-on-primary font-headline uppercase tracking-tighter">
                    {isEditMode ? 'Editar Conductor' : 'Nuevo Conductor'}
                </h3>
                <p className="text-xs text-on-primary/60 font-bold uppercase tracking-widest mt-1">Institución: {SCHOOL_CODE}</p>
              </div>
              <button onClick={() => setShowModal(false)} className="bg-white/10 hover:bg-white/20 p-3 rounded-2xl text-on-primary transition-all">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-10">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Tipo de documento</label>
                  <select 
                    className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none"
                    value={formData.docType}
                    onChange={(e) => setFormData({...formData, docType: e.target.value})}
                  >
                    <option>Cédula</option>
                    <option>Pasaporte</option>
                  </select>
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Número ID (Será su clave)</label>
                  <input 
                    required type="text" 
                    className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none"
                    value={formData.idNumber}
                    disabled={isEditMode}
                    onChange={(e) => setFormData({...formData, idNumber: e.target.value})}
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Nombres</label>
                  <input required type="text" className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none" value={formData.names} onChange={(e) => setFormData({...formData, names: e.target.value})} />
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Apellidos</label>
                  <input required type="text" className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none" value={formData.lastNames} onChange={(e) => setFormData({...formData, lastNames: e.target.value})} />
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Email Corporativo</label>
                  <input 
                    required 
                    type="email" 
                    pattern="^\S+@\S+\.\S+$"
                    title="Por favor ingresa un correo válido con dominio (ej: chofer@rutasegura.com)"
                    className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none" 
                    value={formData.email} 
                    disabled={isEditMode} 
                    onChange={(e) => setFormData({...formData, email: e.target.value})} 
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Celular</label>
                  <input required type="tel" className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none" value={formData.phoneCell} onChange={(e) => setFormData({...formData, phoneCell: e.target.value})} />
                </div>

                <div className="space-y-2 lg:col-span-2">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Cooperativa</label>
                    <input readOnly type="text" className="w-full px-5 py-3.5 bg-slate-100 border-none rounded-2xl text-sm font-bold text-slate-500 outline-none cursor-not-allowed" value={formData.cooperative} />
                </div>

                <div className="lg:col-span-3 space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Dirección de Domicilio</label>
                  <input required type="text" className="w-full px-5 py-3.5 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 outline-none" value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} />
                </div>
              </div>

              <div className="mt-12 flex justify-end gap-4 border-t border-slate-100 pt-8">
                <button type="button" onClick={() => setShowModal(false)} className="px-10 py-4 text-xs font-black text-slate-400 hover:text-slate-600 transition-all uppercase tracking-widest">Cancelar</button>
                <button type="submit" disabled={isSubmitting} className="bg-primary text-on-primary px-12 py-4 rounded-[20px] font-black text-xs uppercase tracking-widest shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-[0.95] transition-all disabled:opacity-50">
                    {isSubmitting ? 'Guardando...' : 'Guardar Conductor'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Modal de Eliminación Personalizado */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-surface rounded-[32px] shadow-2xl max-w-md w-full p-8 animate-in fade-in zoom-in duration-200">
            <div className="text-center">
              <div className="w-20 h-20 bg-error/10 text-error rounded-full flex items-center justify-center mx-auto mb-6">
                <span className="material-symbols-outlined text-4xl">delete_forever</span>
              </div>
              <h3 className="text-xl font-black text-on-surface uppercase tracking-tight">¿Eliminar Conductor?</h3>
              <p className="text-sm text-slate-500 mt-4 leading-relaxed">
                Estás a punto de eliminar a <span className="font-bold text-on-surface">{driverToDelete?.names} {driverToDelete?.lastNames}</span>. 
                Esta acción borrará su cuenta permanentemente y no podrá acceder a la App.
              </p>
            </div>
            
            <div className="flex flex-col gap-3 mt-8">
              <button 
                onClick={handleDeleteDriver}
                disabled={isDeleting}
                className="w-full bg-error text-white py-4 rounded-2xl font-black text-xs uppercase tracking-widest shadow-lg shadow-error/20 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
              >
                {isDeleting ? 'Eliminando...' : 'Sí, Eliminar Permanentemente'}
              </button>
              <button 
                onClick={() => setShowDeleteModal(false)}
                className="w-full bg-slate-100 text-slate-600 py-4 rounded-2xl font-black text-xs uppercase tracking-widest hover:bg-slate-200 transition-all"
              >
                No, Mantener
              </button>
            </div>
          </div>
        </div>
      )}
    </DashboardLayout>
  );
};

export default DriversPage;
