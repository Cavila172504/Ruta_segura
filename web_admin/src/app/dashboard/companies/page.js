"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { authFetch } from '@/lib/api-client';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';

const CompanyLocationPicker = dynamic(
  () => import('@/components/companies/CompanyLocationPicker'),
  { ssr: false, loading: () => <div className="h-52 bg-slate-100 animate-pulse rounded-xl" /> }
);

const CompaniesPage = () => {
    const { profile, loading } = useAuth();
    const router = useRouter();

    const [companies, setCompanies] = useState([]);
    const [totals, setTotals] = useState(null);
    const [fetching, setFetching] = useState(true);
    const [detailCompany, setDetailCompany] = useState(null);

    const [showModal, setShowModal] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');

    const [formData, setFormData] = useState({
        unitCode: '',
        companyName: '',
        transportCompany: '',
        adminName: '',
        adminEmail: '',
        adminPassword: '',
        schoolLat: null,
        schoolLng: null,
        schoolAddress: '',
    });

    const [showEditModal, setShowEditModal] = useState(false);
    const [editData, setEditData] = useState({
        unitCode: '',
        companyName: '',
        transportCompany: '',
        adminName: '',
        newPassword: '',
        schoolLat: null,
        schoolLng: null,
        schoolAddress: '',
    });

    // Estado para el diálogo personalizado de confirmación de eliminación
    const [confirmingDelete, setConfirmingDelete] = useState(null); // guarda el unitCode a eliminar
    const [isDeleting, setIsDeleting] = useState(false);

    useEffect(() => {
        if (!loading && profile?.role !== 'super_admin') {
            router.push('/dashboard');
        } else if (profile?.role === 'super_admin') {
            fetchCompanies();
        }
    }, [loading, profile, router]);

    const fetchCompanies = async () => {
        try {
            setFetching(true);
            const res = await authFetch('/api/companies/stats');
            const data = await res.json();
            if (data.companies) {
                setCompanies(data.companies);
                setTotals(data.totals);
            }
        } catch (error) {
            console.error("Error fetching", error);
        } finally {
            setFetching(false);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({
            ...formData,
            [name]: name === 'unitCode' ? value.toUpperCase() : value,
        });
    };

    const handleCreate = async (e) => {
        e.preventDefault();
        if (formData.schoolLat == null || formData.schoolLng == null) {
            setErrorMsg('Marca la ubicación del colegio en el mapa.');
            return;
        }
        setIsSaving(true);
        setErrorMsg('');

        try {
            const res = await authFetch('/api/companies', {
                method: 'POST',
                body: JSON.stringify(formData)
            });
            const data = await res.json();

            if (!res.ok) {
                setErrorMsg(data.error || 'Ocurrió un error');
            } else {
                setShowModal(false);
                setFormData({
                  unitCode: '', companyName: '', transportCompany: '', adminName: '', adminEmail: '', adminPassword: '',
                  schoolLat: null, schoolLng: null, schoolAddress: '',
                });
                fetchCompanies();
            }
        } catch (err) {
            setErrorMsg('Error de red');
        } finally {
            setIsSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!confirmingDelete) return;
        setIsDeleting(true);
        try {
            const res = await authFetch(`/api/companies?unitCode=${confirmingDelete}`, { method: 'DELETE' });
            const data = await res.json();
            if (!res.ok) {
                console.error('Error:', data.error);
            } else {
                fetchCompanies();
            }
        } catch (error) {
            console.error('Error de red al intentar eliminar:', error);
        } finally {
            setIsDeleting(false);
            setConfirmingDelete(null);
        }
    };

    const openEditModal = (c) => {
        setEditData({
            unitCode: c.unitCode,
            companyName: c.name,
            transportCompany: c.transportCompany || '',
            adminName: c.adminName || 'Admin ' + c.unitCode,
            newPassword: '',
            schoolLat: c.schoolLat ?? null,
            schoolLng: c.schoolLng ?? null,
            schoolAddress: c.schoolAddress || '',
        });
        setShowEditModal(true);
        setDetailCompany(null);
        setErrorMsg('');
    };

    const copyText = (text) => {
        if (typeof navigator !== 'undefined' && text) {
            navigator.clipboard.writeText(text);
        }
    };

    const handleEditChange = (e) => setEditData({ ...editData, [e.target.name]: e.target.value });

    const handleUpdate = async (e) => {
        e.preventDefault();
        setIsSaving(true);
        setErrorMsg('');

        try {
            const res = await authFetch('/api/companies', {
                method: 'PATCH',
                body: JSON.stringify(editData)
            });
            const data = await res.json();

            if (!res.ok) {
                setErrorMsg(data.error || 'Ocurrió un error al actualizar');
            } else {
                setShowEditModal(false);
                fetchCompanies();
            }
        } catch (err) {
            setErrorMsg('Error de red');
        } finally {
            setIsSaving(false);
        }
    };

    if (loading || profile?.role !== 'super_admin') return null;

    return (
        <DashboardLayout title="Instituciones — Super Admin">
            <div className="flex flex-wrap justify-between items-end gap-6 mb-8">
                <div>
                    <h2 className="text-4xl md:text-5xl font-black text-slate-900 font-headline tracking-tighter uppercase italic leading-none mb-3">
                        Centros educativos
                    </h2>
                    <p className="text-lg text-slate-500 font-bold">
                        Administra colegios, credenciales de acceso y métricas para facturación.
                    </p>
                </div>
                <button 
                    onClick={() => setShowModal(true)}
                    className="bg-primary text-on-primary px-10 py-6 rounded-[2rem] font-black uppercase italic tracking-widest flex items-center gap-4 hover:scale-105 transition-all shadow-2xl shadow-blue-200"
                >
                    <span className="material-symbols-outlined text-3xl">add_business</span>
                    Crear Nuevo Colegio
                </button>
            </div>

            {totals && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
                    {[
                        { label: 'Colegios', value: totals.companies },
                        { label: 'Conductores', value: totals.drivers },
                        { label: 'Estudiantes', value: totals.students },
                        { label: 'Activos', value: totals.studentsActive },
                    ].map((t) => (
                        <div key={t.label} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm">
                            <p className="text-2xl font-black text-primary">{t.value}</p>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{t.label}</p>
                        </div>
                    ))}
                </div>
            )}

            {fetching ? (
                <div className="mt-10 text-center text-slate-400 font-bold animate-pulse">Cargando base de datos global...</div>
            ) : (
                <div className="bg-surface-container-lowest rounded-3xl overflow-hidden shadow-sm border border-outline-variant/10">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-slate-50 border-b border-slate-100">
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Código</th>
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Institución</th>
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Ubicación</th>
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Administrador</th>
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Conductores</th>
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Estudiantes</th>
                                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-right">Acciones</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {companies.map((c) => (
                                    <tr key={c.unitCode} className="hover:bg-slate-50/80 transition-all">
                                        <td className="px-6 py-6 font-black text-xl text-primary">{c.unitCode}</td>
                                        <td className="px-6 py-6">
                                            <p className="font-black text-xl text-slate-800 uppercase">{c.name}</p>
                                            <p className="text-xs text-slate-400 font-bold uppercase mt-1">{c.status || 'active'}</p>
                                        </td>
                                        <td className="px-6 py-6 text-center">
                                            {c.hasSchoolLocation ? (
                                              <span className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-700 px-3 py-1 rounded-full text-[10px] font-black uppercase">
                                                <span className="material-symbols-outlined text-sm">location_on</span>
                                                OK
                                              </span>
                                            ) : (
                                              <span className="inline-flex items-center gap-1 bg-amber-50 text-amber-700 px-3 py-1 rounded-full text-[10px] font-black uppercase">
                                                <span className="material-symbols-outlined text-sm">warning</span>
                                                Sin pin
                                              </span>
                                            )}
                                        </td>
                                        <td className="px-6 py-6">
                                            <p className="text-sm font-bold text-slate-700">{c.adminName || '—'}</p>
                                            <p className="text-xs text-slate-500">{c.adminEmail || '—'}</p>
                                        </td>
                                        <td className="px-6 py-6 text-center font-black text-lg">{c.driversCount}</td>
                                        <td className="px-6 py-6 text-center font-black text-lg">{c.studentsTotal}</td>
                                        <td className="px-6 py-6 text-right">
                                            <div className="flex items-center justify-end gap-3 flex-wrap">
                                                <button
                                                    onClick={() => setDetailCompany(c)}
                                                    className="bg-primary text-white px-5 py-3 rounded-xl font-black text-[10px] uppercase tracking-widest hover:scale-105 transition-all"
                                                >
                                                    Ver detalle
                                                </button>
                                                <button
                                                    onClick={() => openEditModal(c)}
                                                    className="bg-slate-100 text-slate-600 px-5 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 hover:text-white transition-all"
                                                >
                                                    Credenciales
                                                </button>
                                                <button
                                                    onClick={() => setConfirmingDelete(c.unitCode)}
                                                    className="p-3 bg-rose-50 text-rose-500 rounded-xl hover:bg-rose-500 hover:text-white transition-all"
                                                >
                                                    <span className="material-symbols-outlined text-sm">delete</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                            ))}
                            {companies.length === 0 && (
                                <tr><td colSpan="7" className="text-center py-10 text-slate-400">No hay instituciones registradas aún.</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            )}

            {/* DETALLE INSTITUCIÓN */}
            {detailCompany && (
                <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl relative border-t-4 border-primary">
                        <button onClick={() => setDetailCompany(null)} className="absolute top-6 right-6 text-slate-400 hover:text-error">
                            <span className="material-symbols-outlined">close</span>
                        </button>
                        <h3 className="text-2xl font-black text-primary uppercase italic mb-1">{detailCompany.name}</h3>
                        <p className="text-sm font-bold text-slate-400 mb-6">Código: {detailCompany.unitCode}</p>

                        <div className="space-y-4 mb-6">
                            <div className="p-4 bg-slate-50 rounded-2xl">
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Correo de acceso del colegio</p>
                                <div className="flex items-center justify-between gap-2">
                                    <p className="font-bold text-slate-800 break-all">{detailCompany.adminEmail || 'No registrado'}</p>
                                    {detailCompany.adminEmail && (
                                        <button type="button" onClick={() => copyText(detailCompany.adminEmail)} className="text-primary text-xs font-black uppercase">Copiar</button>
                                    )}
                                </div>
                                <p className="text-xs text-slate-500 mt-2">El administrador del colegio ingresa con este correo en el panel.</p>
                            </div>
                            <div className="grid grid-cols-3 gap-3">
                                <div className="p-3 bg-emerald-50 rounded-xl text-center">
                                    <p className="text-xl font-black text-emerald-700">{detailCompany.driversCount}</p>
                                    <p className="text-[9px] font-black text-emerald-600 uppercase">Conductores</p>
                                </div>
                                <div className="p-3 bg-blue-50 rounded-xl text-center">
                                    <p className="text-xl font-black text-blue-700">{detailCompany.studentsTotal}</p>
                                    <p className="text-[9px] font-black text-blue-600 uppercase">Estudiantes</p>
                                </div>
                                <div className="p-3 bg-amber-50 rounded-xl text-center">
                                    <p className="text-xl font-black text-amber-700">{detailCompany.studentsPending}</p>
                                    <p className="text-[9px] font-black text-amber-600 uppercase">Pendientes</p>
                                </div>
                            </div>
                        </div>

                        <p className="text-xs text-slate-500 mb-6 leading-relaxed">
                            Conductores, rutas e inscripciones los gestiona el administrador del colegio desde su panel. Desde aquí puedes restablecer su contraseña si la olvidó.
                        </p>

                        <div className="flex gap-3">
                            <button
                                type="button"
                                onClick={() => openEditModal(detailCompany)}
                                className="flex-1 bg-primary text-white py-3 rounded-xl font-black text-xs uppercase tracking-widest"
                            >
                                Restablecer clave
                            </button>
                            <button
                                type="button"
                                onClick={() => setDetailCompany(null)}
                                className="px-6 py-3 rounded-xl border border-slate-200 font-bold text-sm text-slate-600"
                            >
                                Cerrar
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* MODAL DE CREACIÓN */}
            {showModal && (
                <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl relative">
                        <button onClick={() => setShowModal(false)} className="absolute top-6 right-6 text-slate-400 hover:text-error">
                            <span className="material-symbols-outlined">close</span>
                        </button>
                        
                        <h3 className="text-xl font-black text-primary font-headline tracking-tighter uppercase mb-6 flex items-center gap-2">
                            <span className="material-symbols-outlined">domain_add</span>
                            Registrar Colegio
                        </h3>

                        {errorMsg && (
                            <div className="mb-6 bg-error-container/20 text-error text-xs font-bold p-3 rounded-xl border border-error/10">
                                {errorMsg}
                            </div>
                        )}

                        <form onSubmit={handleCreate} className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Código Único (Ej. CAD32)</label>
                                    <input required name="unitCode" value={formData.unitCode} onChange={handleChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-bold text-primary focus:ring-2 focus:ring-primary/20 outline-none uppercase" />
                                </div>
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Nombre Institución</label>
                                    <input required name="companyName" value={formData.companyName} onChange={handleChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-bold text-on-surface focus:ring-2 focus:ring-primary/20 outline-none" />
                                </div>
                            </div>

                            <div className="space-y-1">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Compañía de transporte / Cooperativa</label>
                                <input
                                    name="transportCompany"
                                    value={formData.transportCompany}
                                    onChange={handleChange}
                                    placeholder="Ej. Transportes Escolares del Norte"
                                    className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-primary/20 outline-none"
                                />
                            </div>

                            <CompanyLocationPicker
                              lat={formData.schoolLat}
                              lng={formData.schoolLng}
                              schoolName={formData.companyName}
                              onChange={(lat, lng) => setFormData((prev) => ({ ...prev, schoolLat: lat, schoolLng: lng }))}
                            />
                            <input
                              name="schoolAddress"
                              value={formData.schoolAddress}
                              onChange={handleChange}
                              placeholder="Dirección del colegio (opcional)"
                              className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-primary/20 outline-none"
                            />

                            <div className="pt-4 border-t border-slate-100">
                                <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-4">Credenciales del Administrador</h4>
                                <div className="space-y-4">
                                    <div className="space-y-1">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Nombre del Admin</label>
                                        <input required name="adminName" value={formData.adminName} onChange={handleChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-primary/20 outline-none" />
                                    </div>
                                    <div className="space-y-1">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Correo Electrónico</label>
                                        <input required type="email" name="adminEmail" value={formData.adminEmail} onChange={handleChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-primary/20 outline-none" />
                                    </div>
                                    <div className="space-y-1">
                                        <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Contraseña Asignada</label>
                                        <input required type="text" name="adminPassword" value={formData.adminPassword} onChange={handleChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-primary/20 outline-none" />
                                    </div>
                                </div>
                            </div>

                            <div className="pt-6">
                                <button type="submit" disabled={isSaving} className="w-full bg-primary text-white py-4 rounded-xl font-bold hover:bg-primary/90 transition-all shadow-md flex justify-center items-center">
                                    {isSaving ? <div className="animate-spin w-5 h-5 border-2 border-white/30 border-t-white rounded-full"></div> : 'GENERAR SISTEMA Y CREDENCIALES'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL DE EDICIÓN Y RESET DE CLAVE */}
            {showEditModal && (
                <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl relative border-t-4 border-secondary">
                        <button onClick={() => setShowEditModal(false)} className="absolute top-6 right-6 text-slate-400 hover:text-error">
                            <span className="material-symbols-outlined">close</span>
                        </button>
                        
                        <h3 className="text-xl font-black text-secondary font-headline tracking-tighter uppercase mb-2 flex items-center gap-2">
                            <span className="material-symbols-outlined">lock_reset</span>
                            Credenciales del administrador
                        </h3>
                        <p className="text-xs text-slate-500 font-bold mb-6">Comparte el correo con el colegio. Si olvidó la clave, escribe una nueva abajo.</p>

                        {errorMsg && (
                            <div className="mb-6 bg-error-container/20 text-error text-xs font-bold p-3 rounded-xl border border-error/10">
                                {errorMsg}
                            </div>
                        )}

                        <form onSubmit={handleUpdate} className="space-y-4">
                            <div className="space-y-1">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Código Único (Fijo)</label>
                                <input readOnly value={editData.unitCode} className="w-full p-3 bg-slate-100 border-none rounded-xl text-sm font-bold text-slate-400 cursor-not-allowed" />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Institución</label>
                                    <input name="companyName" value={editData.companyName} onChange={handleEditChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-bold focus:ring-2 focus:ring-secondary/20 outline-none" />
                                </div>
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Nombre Admin</label>
                                    <input name="adminName" value={editData.adminName} onChange={handleEditChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-secondary/20 outline-none" />
                                </div>
                            </div>

                            <div className="space-y-1">
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Compañía de transporte / Cooperativa</label>
                                <input
                                    name="transportCompany"
                                    value={editData.transportCompany}
                                    onChange={handleEditChange}
                                    placeholder="Cooperativa asignada a esta sede"
                                    className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-secondary/20 outline-none"
                                />
                            </div>

                            <CompanyLocationPicker
                              lat={editData.schoolLat}
                              lng={editData.schoolLng}
                              schoolName={editData.companyName}
                              onChange={(lat, lng) => setEditData((prev) => ({ ...prev, schoolLat: lat, schoolLng: lng }))}
                            />
                            <input
                              name="schoolAddress"
                              value={editData.schoolAddress}
                              onChange={handleEditChange}
                              placeholder="Dirección del colegio"
                              className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-semibold focus:ring-2 focus:ring-secondary/20 outline-none"
                            />

                            <div className="p-4 bg-tertiary-container/30 rounded-xl border border-tertiary/10 mt-4">
                                <div className="flex items-center gap-2 mb-2 text-tertiary">
                                    <span className="material-symbols-outlined text-sm">lock_reset</span>
                                    <h4 className="text-[10px] font-black text-tertiary uppercase tracking-widest">Reseteo de Seguridad</h4>
                                </div>
                                <p className="text-[10px] text-slate-600 font-medium mb-3">Si el cliente olvidó su acceso, escribe una nueva clave aquí. Si la dejas en blanco, no se modificará.</p>
                                <input 
                                    type="text" 
                                    name="newPassword" 
                                    value={editData.newPassword} 
                                    onChange={handleEditChange} 
                                    placeholder="Dejar en blanco para mantener la actual..." 
                                    className="w-full p-3 bg-white border border-slate-200 rounded-xl text-sm font-semibold focus:ring-2 focus:ring-tertiary/50 outline-none placeholder:text-slate-400" 
                                />
                            </div>

                            <div className="pt-6">
                                <button type="submit" disabled={isSaving} className="w-full bg-secondary text-white py-4 rounded-xl font-bold hover:bg-secondary/90 transition-all shadow-md flex justify-center items-center">
                                    {isSaving ? <div className="animate-spin w-5 h-5 border-2 border-white/30 border-t-white rounded-full"></div> : 'GUARDAR CAMBIOS'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL DE CONFIRMACIÓN DE ELIMINACIÓN */}
            {confirmingDelete && (
                <div className="fixed inset-0 z-[2000] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl border-t-4 border-error">
                        <div className="flex items-center gap-4 mb-4">
                            <div className="w-12 h-12 rounded-full bg-error/10 flex items-center justify-center">
                                <span className="material-symbols-outlined text-error text-2xl">warning</span>
                            </div>
                            <div>
                                <h3 className="text-lg font-black text-on-surface">¿Eliminar colegio?</h3>
                                <p className="text-xs text-slate-400 font-bold">Código: <span className="text-error">{confirmingDelete}</span></p>
                            </div>
                        </div>
                        <p className="text-sm text-slate-600 font-medium mb-8 leading-relaxed">
                            Esta acción eliminará <strong>permanentemente</strong> el registro del colegio, los permisos del administrador y su cuenta de acceso. Esta operación <strong>no se puede deshacer</strong>.
                        </p>
                        <div className="flex gap-4">
                            <button
                                onClick={() => setConfirmingDelete(null)}
                                disabled={isDeleting}
                                className="flex-1 py-3 rounded-xl border-2 border-slate-200 text-slate-600 font-bold text-sm hover:bg-slate-50 transition-colors"
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={handleDelete}
                                disabled={isDeleting}
                                className="flex-1 py-3 rounded-xl bg-error text-white font-bold text-sm hover:bg-error/90 transition-colors flex items-center justify-center gap-2"
                            >
                                {isDeleting ? (
                                    <div className="animate-spin w-5 h-5 border-2 border-white/30 border-t-white rounded-full"></div>
                                ) : (
                                    <>
                                        <span className="material-symbols-outlined text-sm">delete_forever</span>
                                        Confirmar Eliminación
                                    </>
                                )}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
};

export default CompaniesPage;
