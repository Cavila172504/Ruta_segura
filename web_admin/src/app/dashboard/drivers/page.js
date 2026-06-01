"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy, doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import { authFetch } from '@/lib/api-client';

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
    phoneCell: '',
    address: '',
    cooperative: ''
  });

  const emptyForm = {
    docType: 'Cédula',
    idNumber: '',
    names: '',
    lastNames: '',
    email: '',
    phoneCell: '',
    address: '',
    cooperative: '',
  };

  const fetchSchoolTransportCompany = async () => {
    if (!SCHOOL_CODE) return '';
    const snap = await getDoc(doc(db, 'companies', SCHOOL_CODE));
    if (!snap.exists()) return '';
    const data = snap.data();
    return data.transportCompany || data.cooperative || '';
  };

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

  const handleOpenCreateModal = async () => {
    const cooperative = await fetchSchoolTransportCompany();
    setFormData({ ...emptyForm, cooperative });
    setIsEditMode(false);
    setShowModal(true);
  };

  const handleOpenEditModal = async (driver) => {
    const schoolCoop = await fetchSchoolTransportCompany();
    setFormData({
      docType: driver.docType || 'Cédula',
      idNumber: driver.idNumber || '',
      names: driver.names || '',
      lastNames: driver.lastNames || '',
      email: driver.email || '',
      phoneCell: driver.phoneCell || '',
      address: driver.address || '',
      cooperative: driver.cooperative || schoolCoop || '',
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

      const idNumber = formData.idNumber?.trim() || '';
      if (idNumber.length < 6) {
        alert('La cédula debe tener al menos 6 dígitos (es la contraseña de acceso en la app del conductor).');
        setIsSubmitting(false);
        return;
      }

      const response = await authFetch(url, {
        method: method,
        body: JSON.stringify({
          ...formData,
          idNumber,
          name: `${formData.names} ${formData.lastNames}`,
          unitCode: SCHOOL_CODE,
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
      const response = await authFetch(`/api/drivers?id=${driverToDelete.id}&unitCode=${SCHOOL_CODE}`, {
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
      <section className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-extrabold text-on-surface tracking-tight mb-1 uppercase italic">Conductores</h2>
          <p className="text-xs text-on-surface-variant font-bold opacity-60">Administración de transporte — {SCHOOL_CODE}.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[240px]">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-lg">search</span>
            <input 
              type="text"
              className="w-full pl-9 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs outline-none shadow-sm focus:border-primary transition-colors"
              placeholder="Buscar conductor..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          {profile?.role !== 'viewer' && (
            <button 
              onClick={handleOpenCreateModal}
              className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary px-4 py-2 rounded-xl font-black text-xs uppercase tracking-widest transition-all shadow-md shadow-primary/20"
            >
              <span className="material-symbols-outlined text-base">person_add</span>
              Nuevo Conductor
            </button>
          )}
        </div>
      </section>

      <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-100">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-100">
                <th className="px-5 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">Nombre Conductor / Email</th>
                <th className="px-5 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">ID (Clave)</th>
                <th className="px-5 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">Cooperativa</th>
                <th className="px-5 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none text-center whitespace-nowrap">Estado</th>
                {profile?.role !== 'viewer' && <th className="px-5 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none text-right">Acciones</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {filteredDrivers.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-6 py-10 text-center text-slate-400">Sin conductores registrados.</td>
                </tr>
              ) : (
                filteredDrivers.map((driver) => (
                  <tr key={driver.id} className="hover:bg-blue-50/20 transition-colors group">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary text-xs font-black uppercase">
                          {driver.names?.charAt(0)}{driver.lastNames?.charAt(0)}
                        </div>
                        <div>
                          <div className="font-black text-slate-800 text-sm uppercase leading-none mb-1">{driver.names} {driver.lastNames}</div>
                          <div className="text-[10px] text-slate-400 font-bold italic">{driver.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3">
                      <div className="text-slate-600 font-black text-xs uppercase tracking-tighter italic">{driver.idNumber}</div>
                    </td>
                    <td className="px-5 py-3">
                      <span className="text-[10px] font-black text-slate-500 uppercase">{driver.cooperative}</span>
                    </td>
                    <td className="px-5 py-3 text-center">
                      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[9px] font-black uppercase bg-emerald-50 text-emerald-600 border border-emerald-100">
                        Activo
                      </span>
                    </td>
                    {profile?.role !== 'viewer' && (
                      <td className="px-5 py-3 text-right">
                        <div className="flex justify-end gap-2">
                           <button 
                            type="button"
                            onClick={(e) => { e.stopPropagation(); handleOpenEditModal(driver); }}
                            className="flex items-center gap-1 bg-white hover:bg-primary hover:text-white text-slate-400 px-3 py-1.5 rounded-lg transition-all border border-slate-200"
                          >
                            <span className="material-symbols-outlined text-xs">edit</span>
                            <span className="text-[10px] font-black tracking-widest uppercase">Editar</span>
                          </button>
                          
                          <button 
                            type="button"
                            onClick={(e) => { e.stopPropagation(); openDeleteModal(driver); }}
                            className="flex items-center gap-1 bg-white hover:bg-error hover:text-white text-slate-400 px-3 py-1.5 rounded-lg transition-all border border-slate-200"
                          >
                            <span className="material-symbols-outlined text-xs">delete</span>
                            <span className="text-[10px] font-black tracking-widest uppercase">Baja</span>
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full overflow-hidden flex flex-col animate-in fade-in slide-in-from-bottom-2 duration-200">
            <div className="bg-primary px-6 py-4 flex justify-between items-center">
              <div>
                <h3 className="text-lg font-black text-on-primary font-headline uppercase tracking-tighter italic">
                    {isEditMode ? 'Editar Perfil Conductor' : 'Ingreso Nuevo Conductor'}
                </h3>
                <p className="text-[10px] text-on-primary/70 font-black uppercase tracking-widest">Sede: {SCHOOL_CODE}</p>
              </div>
              <button onClick={() => setShowModal(false)} className="text-on-primary/60 hover:text-on-primary transition-colors">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Documento</label>
                  <select 
                    className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors"
                    value={formData.docType}
                    onChange={(e) => setFormData({...formData, docType: e.target.value})}
                  >
                    <option>Cédula</option>
                    <option>Pasaporte</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">ID (Será su Contraseña)</label>
                  <input 
                    required type="text" 
                    placeholder="Ej: 1725049..."
                    className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors"
                    value={formData.idNumber}
                    disabled={isEditMode}
                    onChange={(e) => setFormData({...formData, idNumber: e.target.value})}
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Nombres Completos</label>
                  <input required type="text" className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors" value={formData.names} onChange={(e) => setFormData({...formData, names: e.target.value})} />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Apellidos Completos</label>
                  <input required type="text" className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors" value={formData.lastNames} onChange={(e) => setFormData({...formData, lastNames: e.target.value})} />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Correo Electrónico</label>
                  <input 
                    required 
                    type="email" 
                    placeholder="chofer@ejemplo.com"
                    className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors" 
                    value={formData.email} 
                    disabled={isEditMode} 
                    onChange={(e) => setFormData({...formData, email: e.target.value})} 
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Teléfono Móvil</label>
                  <input required type="tel" className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors" value={formData.phoneCell} onChange={(e) => setFormData({...formData, phoneCell: e.target.value})} />
                </div>

                <div className="md:col-span-2 rounded-xl bg-primary/5 border border-primary/10 px-4 py-3">
                  <p className="text-[10px] font-bold text-primary leading-relaxed">
                    La app del conductor usa la <span className="uppercase">cédula</span> como contraseña de ingreso (mín. 6 caracteres).
                  </p>
                </div>

                <div className="space-y-1 md:col-span-2">
                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Compañía / Cooperativa</label>
                    <input
                      type="text"
                      placeholder="Cooperativa de transporte de esta sede"
                      className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors"
                      value={formData.cooperative}
                      onChange={(e) => setFormData({ ...formData, cooperative: e.target.value })}
                    />
                    <p className="text-[9px] text-slate-400 font-medium pl-1">Por defecto se usa la cooperativa configurada en la institución.</p>
                </div>

                <div className="md:col-span-2 space-y-1">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Dirección de Domicilio actual</label>
                  <input required type="text" className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 outline-none focus:border-primary transition-colors" value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} />
                </div>
              </div>

              <div className="mt-8 flex justify-end gap-3 border-t border-slate-100 pt-6">
                <button type="button" onClick={() => setShowModal(false)} className="px-6 py-2 text-[10px] font-black text-slate-400 hover:text-slate-600 transition-all uppercase tracking-widest">Cancelar</button>
                <button type="submit" disabled={isSubmitting} className="bg-primary text-white px-8 py-2 rounded-xl font-black text-[10px] uppercase tracking-widest shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.95] transition-all disabled:opacity-50">
                    {isSubmitting ? 'Procesando...' : 'Registrar Conductor'}
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
