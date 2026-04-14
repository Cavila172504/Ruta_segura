"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const RoutesPage = () => {
  const [routes, setRoutes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  const SCHOOL_CODE = 'CAD31';

  useEffect(() => {
    const routesRef = collection(db, 'companies', SCHOOL_CODE, 'routes');
    const unsubscribe = onSnapshot(routesRef, (snapshot) => {
      const routesList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setRoutes(routesList);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const filteredRoutes = routes.filter(r => 
    r.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.id?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <DashboardLayout title="Gestión de Rutas">
      <section className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
        <div>
          <h2 className="text-3xl font-extrabold text-on-surface tracking-tight mb-2">Rutas ({SCHOOL_CODE})</h2>
          <p className="text-on-surface-variant max-w-md">Supervise y optimice el transporte escolar en tiempo real.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[300px]">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-xl">search</span>
            <input 
              type="text"
              className="w-full pl-10 pr-4 py-2.5 bg-surface-container-lowest border-none rounded-xl text-sm focus:ring-2 focus:ring-primary/20 shadow-sm outline-none"
              placeholder="Buscar ruta..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </section>

      <div className="bg-surface-container-lowest rounded-3xl overflow-hidden shadow-sm border border-outline-variant/10">
        <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">ID Ruta</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Nombre</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Estado</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container">
              {filteredRoutes.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-6 py-10 text-center text-slate-400">{loading ? 'Cargando...' : 'No hay rutas.'}</td>
                </tr>
              ) : (
                filteredRoutes.map((route) => (
                  <tr key={route.id}>
                    <td className="px-6 py-5 font-mono text-sm font-bold text-primary">{route.id}</td>
                    <td className="px-6 py-5 font-bold text-on-surface">{route.name}</td>
                    <td className="px-6 py-5">
                      <span className="px-3 py-1 bg-green-50 text-green-600 rounded-full text-[10px] font-black uppercase">Activa</span>
                    </td>
                    <td className="px-6 py-5 text-right space-x-2">
                        <button className="p-2 text-slate-400 hover:text-primary transition-all"><span className="material-symbols-outlined">edit</span></button>
                        <button className="p-2 text-slate-400 hover:text-error transition-all"><span className="material-symbols-outlined">delete</span></button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
        </table>
      </div>
    </DashboardLayout>
  );
};

export default RoutesPage;
