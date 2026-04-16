"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';

const CompaniesPage = () => {
    const { profile, loading, activeUnitCode, setActiveUnitCode } = useAuth();
    const router = useRouter();

    const [companies, setCompanies] = useState([]);
    const [fetching, setFetching] = useState(true);

    const [showModal, setShowModal] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');

    const [formData, setFormData] = useState({
        unitCode: '',
        companyName: '',
        adminName: '',
        adminEmail: '',
        adminPassword: ''
    });

    const [showEditModal, setShowEditModal] = useState(false);
    const [editData, setEditData] = useState({
        unitCode: '',
        companyName: '',
        adminName: '',
        newPassword: ''
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

    const handleSwitchSchool = (code) => {
        setActiveUnitCode(code);
        router.push('/dashboard');
    };

    const fetchCompanies = async () => {
        try {
            setFetching(true);
            const res = await fetch('/api/companies');
            const data = await res.json();
            if (data.companies) {
                setCompanies(data.companies);
            }
        } catch (error) {
            console.error("Error fetching", error);
        } finally {
            setFetching(false);
        }
    };

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleCreate = async (e) => {
        e.preventDefault();
        setIsSaving(true);
        setErrorMsg('');

        try {
            const res = await fetch('/api/companies', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            const data = await res.json();

            if (!res.ok) {
                setErrorMsg(data.error || 'Ocurrió un error');
            } else {
                setShowModal(false);
                setFormData({ unitCode: '', companyName: '', adminName: '', adminEmail: '', adminPassword: '' });
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
            const res = await fetch(`/api/companies?unitCode=${confirmingDelete}`, { method: 'DELETE' });
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
            adminName: c.adminName || 'Admin ' + c.unitCode, // Default si no se mapeó el adminName
            newPassword: ''
        });
        setShowEditModal(true);
        setErrorMsg('');
    };

    const handleEditChange = (e) => setEditData({ ...editData, [e.target.name]: e.target.value });

    const handleUpdate = async (e) => {
        e.preventDefault();
        setIsSaving(true);
        setErrorMsg('');

        try {
            const res = await fetch('/api/companies', {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
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
        <DashboardLayout title="Gestión de Empresas (Super Admin)">
            <div className="flex justify-between items-end mb-12">
                <div>
                    <h2 className="text-5xl font-black text-slate-900 font-headline tracking-tighter uppercase italic leading-none mb-3">Soporte e Instituciones</h2>
                    <p className="text-xl text-slate-500 font-bold italic">Selecciona el colegio que deseas gestionar o crea uno nuevo.</p>
                </div>
                <button 
                    onClick={() => setShowModal(true)}
                    className="bg-primary text-on-primary px-10 py-6 rounded-[2rem] font-black uppercase italic tracking-widest flex items-center gap-4 hover:scale-105 transition-all shadow-2xl shadow-blue-200"
                >
                    <span className="material-symbols-outlined text-3xl">add_business</span>
                    Crear Nuevo Colegio
                </button>
            </div>

            {fetching ? (
                <div className="mt-10 text-center text-slate-400 font-bold animate-pulse">Cargando base de datos global...</div>
            ) : (
                <div className="bg-surface-container-lowest rounded-3xl overflow-hidden shadow-sm border border-outline-variant/10">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-slate-50 border-b border-slate-100">
                                <th className="px-10 py-8 text-xs font-black text-slate-400 uppercase tracking-[0.2em] italic">Estado Soporte</th>
                                <th className="px-10 py-8 text-xs font-black text-slate-400 uppercase tracking-[0.2em] italic">Código</th>
                                <th className="px-10 py-8 text-xs font-black text-slate-400 uppercase tracking-[0.2em] italic">Institución Educativa</th>
                                <th className="px-10 py-8 text-xs font-black text-slate-400 uppercase tracking-[0.2em] italic text-right">Mando Global</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {companies.map((c) => {
                                const isCurrent = activeUnitCode === c.unitCode;
                                return (
                                    <tr key={c.id} className={`group transition-all ${isCurrent ? 'bg-blue-50/50' : 'hover:bg-slate-50'}`}>
                                        <td className="px-10 py-8">
                                            {isCurrent ? (
                                                <div className="flex items-center gap-3 text-emerald-500">
                                                    <div className="w-4 h-4 bg-emerald-500 rounded-full animate-ping"></div>
                                                    <span className="text-xs font-black uppercase tracking-widest italic leading-none">Gestionando Actualmente</span>
                                                </div>
                                            ) : (
                                                <span className="text-xs font-bold text-slate-300 uppercase italic">Desconectado</span>
                                            )}
                                        </td>
                                        <td className="px-10 py-8 font-black text-2xl text-primary tracking-tighter italic">{c.unitCode}</td>
                                        <td className="px-10 py-8">
                                            <p className="font-black text-3xl text-slate-800 uppercase leading-none mb-1 tracking-tight">{c.name}</p>
                                            <p className="text-sm font-bold text-slate-400 italic uppercase">ADMIN: {c.adminEmail}</p>
                                        </td>
                                        <td className="px-10 py-8 text-right">
                                            <div className="flex items-center justify-end gap-6">
                                                <button 
                                                    onClick={() => handleSwitchSchool(c.unitCode)}
                                                    className={`px-8 py-4 rounded-2xl font-black text-sm uppercase italic tracking-widest transition-all ${isCurrent ? 'bg-slate-200 text-slate-400 cursor-not-allowed' : 'bg-emerald-500 text-white shadow-lg shadow-emerald-100 hover:scale-105 active:scale-95'}`}
                                                    disabled={isCurrent}
                                                >
                                                    {isCurrent ? 'DENTRO' : 'ENTRAR'}
                                                </button>
                                                <button 
                                                    onClick={() => openEditModal(c)}
                                                    className="bg-slate-100 text-slate-500 px-6 py-4 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 hover:text-white transition-all shadow-sm"
                                                >
                                                    MODIFICAR
                                                </button>
                                                <button 
                                                    onClick={() => setConfirmingDelete(c.unitCode)}
                                                    className="p-4 bg-rose-50 text-rose-500 rounded-2xl hover:bg-rose-500 hover:text-white transition-all shadow-sm"
                                                >
                                                    <span className="material-symbols-outlined text-sm">delete</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                            {companies.length === 0 && (
                                <tr><td colSpan="4" className="text-center py-10 text-slate-400">No hay instituciones registradas aún.</td></tr>
                            )}
                        </tbody>
                    </table>
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
                            <span className="material-symbols-outlined">edit_square</span>
                            Modificar Colegio
                        </h3>
                        <p className="text-xs text-slate-500 font-bold mb-6">Actualiza datos o resetea la contraseña de acceso.</p>

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
