"use client";
import React from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import Link from 'next/link';

const ProfilePage = () => {
    const { profile } = useAuth();

    return (
        <DashboardLayout title="Mi Perfil">
            <div className="max-w-4xl mx-auto">
                <div className="bg-surface-container-lowest rounded-3xl overflow-hidden shadow-sm border border-outline-variant/10">
                    {/* Header decorativo */}
                    <div className="h-32 bg-gradient-to-r from-primary/10 to-primary/30 relative">
                        <div className="absolute -bottom-12 left-10">
                            <img 
                                alt="User Avatar" 
                                className="w-24 h-24 rounded-full object-cover border-4 border-white shadow-lg" 
                                src={profile?.photoUrl || "https://ui-avatars.com/api/?name=" + (profile?.name || 'Admin') + "&background=3b309e&color=fff"} 
                            />
                        </div>
                    </div>

                    <div className="pt-16 pb-10 px-10">
                        <div className="flex justify-between items-start">
                            <div>
                                <h2 className="text-2xl font-black font-headline text-on-surface uppercase tracking-tight">
                                    {profile?.name || 'Administrador'}
                                </h2>
                                <p className="text-sm font-bold text-primary mt-1 flex items-center gap-1 uppercase tracking-widest">
                                    <span className="material-symbols-outlined text-[16px]">verified</span>
                                    {profile?.role === 'super_admin' ? 'Super Administrador Global' : `Administrador Unidad ${profile?.unitCode || 'N/A'}`}
                                </p>
                            </div>
                            <button className="bg-primary text-on-primary px-6 py-2.5 rounded-2xl font-bold text-sm shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all">
                                Editar Datos
                            </button>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mt-12">
                            <div className="space-y-6">
                                <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-[2px]">Datos de Contacto</h3>
                                <div className="space-y-4">
                                    <div className="flex items-center gap-4 group">
                                        <div className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400 group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                                            <span className="material-symbols-outlined">mail</span>
                                        </div>
                                        <div>
                                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Email</p>
                                            <p className="text-sm font-semibold text-on-surface">{profile?.email || 'peticion@rutasegura.com'}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-4 group">
                                        <div className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400 group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                                            <span className="material-symbols-outlined">phone</span>
                                        </div>
                                        <div>
                                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Teléfono</p>
                                            <p className="text-sm font-semibold text-on-surface">{profile?.phone || 'Sin registrar'}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="space-y-6">
                                <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-[2px]">Seguridad de Acceso</h3>
                                <div className="p-5 bg-slate-50/50 rounded-2xl border border-outline-variant/10">
                                    <p className="text-xs text-slate-600 leading-relaxed font-medium">
                                        Su cuenta está protegida por un sistema de cifrado de extremo a extremo. Como {profile?.role === 'super_admin' ? 'Super Administrador' : 'Administrador'}, puede acceder a la gestión de unidades y conductores vinculados.
                                    </p>
                                    <button className="mt-4 text-xs font-black text-primary uppercase tracking-widest hover:underline decoration-2">Cambiar Contraseña</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {profile?.role === 'super_admin' && (
                    <div className="mt-8 bg-primary/5 border border-primary/20 p-8 rounded-3xl">
                        <div className="flex items-center gap-4 text-primary">
                            <span className="material-symbols-outlined text-3xl">shield_person</span>
                            <div>
                                <h3 className="text-lg font-black font-headline uppercase tracking-tight tracking-widest">Panel de Super Usuario</h3>
                                <p className="text-xs font-medium text-primary/80">Has desbloqueado funciones de gestión multitenant.</p>
                            </div>
                        </div>
                        <div className="mt-6 flex gap-4">
                            <Link href="/dashboard/companies" className="bg-white text-primary border border-primary/20 px-4 py-2 rounded-xl text-xs font-bold hover:bg-primary hover:text-white transition-all">Crear Nueva Unidad (Empresa)</Link>
                            <Link href="/dashboard/companies" className="bg-white text-primary border border-primary/20 px-4 py-2 rounded-xl text-xs font-bold hover:bg-primary hover:text-white transition-all">Reporte Global de Flota</Link>
                        </div>
                    </div>
                )}
            </div>
        </DashboardLayout>
    );
};

export default ProfilePage;
