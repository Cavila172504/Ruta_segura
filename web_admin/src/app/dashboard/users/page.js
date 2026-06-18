"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, doc, deleteDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';
import { authFetch } from '@/lib/api-client';
import { useToast } from '@/context/ToastContext';

const UsersManagementPage = () => {
    const { profile } = useAuth();
    const toast = useToast();
    const [users, setUsers] = useState([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [loading, setLoading] = useState(false);

    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
        unitCode: '',
        role: 'viewer'
    });

    useEffect(() => {
        // Solo el super_admin puede ver esta página
        if (profile?.role !== 'super_admin') return;

        const q = query(collection(db, 'users', 'admins', 'members'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            setUsers(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        });

        return () => unsubscribe();
    }, [profile]);

    const handleCreateUser = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            const response = await authFetch('/api/users/create', {
                method: 'POST',
                body: JSON.stringify(formData)
            });

            const data = await response.json();
            if (data.success) {
                toast.success('Usuario creado exitosamente');
                setIsModalOpen(false);
                setFormData({ name: '', email: '', password: '', unitCode: '', role: 'viewer' });
            } else {
                toast.error('Error: ' + data.error);
            }
        } catch (error) {
            toast.error('Error de red: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    if (profile?.role !== 'super_admin') {
        return (
            <DashboardLayout title="Acceso Denegado">
                <div className="bg-white p-10 rounded-2xl text-center shadow-sm">
                    <span className="material-symbols-outlined text-6xl text-error mb-4">lock</span>
                    <h2 className="text-2xl font-black text-on-surface uppercase">No tienes permisos</h2>
                    <p className="text-slate-500 mt-2 text-sm font-bold">Solo el Administrador Global puede gestionar usuarios.</p>
                </div>
            </DashboardLayout>
        );
    }

    return (
        <DashboardLayout title="Gestión de Usuarios">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h3 className="font-headline text-2xl font-black text-on-surface uppercase tracking-tight">Cuentas de Acceso</h3>
                    <p className="text-slate-500 text-xs font-bold uppercase tracking-widest mt-1">Crea accesos para monitores (colegios) o administradores</p>
                </div>
                <button 
                    onClick={() => setIsModalOpen(true)}
                    className="bg-primary text-white px-6 py-3 rounded-xl font-black text-[11px] uppercase tracking-widest shadow-xl shadow-primary/20 hover:scale-105 transition-all flex items-center gap-2"
                >
                    <span className="material-symbols-outlined text-sm">person_add</span>
                    Nuevo Usuario
                </button>
            </div>

            <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-100">
                <table className="w-full text-left border-collapse">
                    <thead>
                        <tr className="bg-slate-50 border-b border-slate-100">
                            <th className="px-6 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Usuario</th>
                            <th className="px-6 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Email</th>
                            <th className="px-6 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Colegio</th>
                            <th className="px-6 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Rol / Permisos</th>
                            <th className="px-6 py-4 text-[10px] font-black text-slate-400 uppercase tracking-widest">Acciones</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-50">
                        {users.map(u => (
                            <tr key={u.id} className="hover:bg-slate-50/50 transition-colors">
                                <td className="px-6 py-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-xs uppercase">
                                            {u.name?.charAt(0)}
                                        </div>
                                        <span className="text-sm font-bold text-on-surface">{u.name}</span>
                                    </div>
                                </td>
                                <td className="px-6 py-4 text-sm text-slate-600">{u.email}</td>
                                <td className="px-6 py-4">
                                    <span className="text-[11px] font-black text-primary bg-primary/5 px-2 py-1 rounded tracking-widest uppercase">
                                        {u.unitCode}
                                    </span>
                                </td>
                                <td className="px-6 py-4">
                                    <span className={`text-[10px] font-black px-2 py-1 rounded uppercase tracking-widest ${
                                        u.role === 'admin' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700'
                                    }`}>
                                        {u.role === 'viewer' ? '👓 Solo Lectura' : '🛠️ Administrador'}
                                    </span>
                                </td>
                                <td className="px-6 py-4">
                                    <button 
                                        onClick={async () => {
                                            if(window.confirm('¿Eliminar acceso?')) {
                                                await deleteDoc(doc(db, 'users', 'admins', 'members', u.id));
                                            }
                                        }}
                                        className="text-error hover:bg-error/10 p-2 rounded-lg transition-colors material-symbols-outlined"
                                    >
                                        delete
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* MODAL NUEVO USUARIO */}
            {isModalOpen && (
                <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[100] flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl w-full max-w-md p-8 shadow-2xl animate-in fade-in zoom-in duration-300">
                        <div className="flex justify-between items-start mb-6">
                            <div>
                                <h4 className="text-xl font-black text-on-surface uppercase tracking-tight">Nuevo Acceso</h4>
                                <p className="text-slate-400 text-[10px] font-bold uppercase tracking-widest">Configura las credenciales del usuario</p>
                            </div>
                            <button onClick={() => setIsModalOpen(false)} className="material-symbols-outlined text-slate-400 hover:text-slate-600">close</button>
                        </div>

                        <form onSubmit={handleCreateUser} className="space-y-4">
                            <div>
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-1 ml-1">Nombre Completo</label>
                                <input 
                                    required
                                    type="text" 
                                    placeholder="Ej: Colegio CADE - Monitoreo"
                                    className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-3 text-sm outline-none focus:border-primary transition-colors"
                                    value={formData.name}
                                    onChange={e => setFormData({...formData, name: e.target.value})}
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-1 ml-1">Correo Electrónico</label>
                                <input 
                                    required
                                    type="email" 
                                    placeholder="email@colegio.com"
                                    className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-3 text-sm outline-none focus:border-primary transition-colors"
                                    value={formData.email}
                                    onChange={e => setFormData({...formData, email: e.target.value})}
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-1 ml-1">Contraseña</label>
                                <input 
                                    required
                                    type="password" 
                                    placeholder="••••••••"
                                    className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-3 text-sm outline-none focus:border-primary transition-colors"
                                    value={formData.password}
                                    onChange={e => setFormData({...formData, password: e.target.value})}
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-1 ml-1">Código Colegio</label>
                                    <input 
                                        required
                                        type="text" 
                                        placeholder="CAD31"
                                        className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-3 text-sm outline-none focus:border-primary transition-colors uppercase"
                                        value={formData.unitCode}
                                        onChange={e => setFormData({...formData, unitCode: e.target.value.toUpperCase()})}
                                    />
                                </div>
                                <div>
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-1 ml-1">Rol</label>
                                    <select 
                                        className="w-full bg-slate-50 border border-slate-100 rounded-xl px-4 py-3 text-sm outline-none focus:border-primary transition-colors"
                                        value={formData.role}
                                        onChange={e => setFormData({...formData, role: e.target.value})}
                                    >
                                        <option value="viewer">Solo Lectura</option>
                                        <option value="admin">Administrador</option>
                                    </select>
                                </div>
                            </div>

                            <button 
                                type="submit"
                                disabled={loading}
                                className="w-full bg-primary text-white py-4 rounded-2xl font-black text-xs uppercase tracking-[2px] shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all mt-4 disabled:opacity-50"
                            >
                                {loading ? 'Creando Usuario...' : 'Crear Acceso Ahora'}
                            </button>
                        </form>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
};

export default UsersManagementPage;
