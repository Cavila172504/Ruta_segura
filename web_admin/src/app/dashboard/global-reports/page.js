"use client";
import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { authFetch } from '@/lib/api-client';
import * as XLSX from 'xlsx';

export default function GlobalReportsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [data, setData] = useState(null);
  const [fetching, setFetching] = useState(true);

  useEffect(() => {
    if (!loading && profile?.role !== 'super_admin') {
      router.push('/dashboard');
    }
  }, [loading, profile, router]);

  useEffect(() => {
    if (profile?.role !== 'super_admin') return;
    (async () => {
      try {
        setFetching(true);
        const res = await authFetch('/api/companies/stats');
        const json = await res.json();
        if (res.ok) setData(json);
      } catch (e) {
        console.error(e);
      } finally {
        setFetching(false);
      }
    })();
  }, [profile]);

  const exportExcel = () => {
    if (!data?.companies) return;
    const rows = data.companies.map((c) => ({
      Codigo: c.unitCode,
      Institucion: c.name,
      Admin: c.adminName || '',
      Correo: c.adminEmail || '',
      Conductores: c.driversCount,
      EstudiantesTotal: c.studentsTotal,
      EstudiantesActivos: c.studentsActive,
      Pendientes: c.studentsPending,
      Estado: c.status,
    }));
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Facturacion');
    XLSX.writeFile(wb, `RutaSegura_Global_${new Date().toISOString().slice(0, 10)}.xlsx`);
  };

  if (loading || profile?.role !== 'super_admin') return null;

  const totals = data?.totals || { companies: 0, drivers: 0, students: 0, studentsActive: 0 };

  return (
    <DashboardLayout title="Informes Globales (Super Admin)">
      <div className="flex flex-wrap justify-between items-end gap-6 mb-10">
        <div>
          <h2 className="text-4xl font-black text-slate-900 font-headline tracking-tighter uppercase italic leading-none mb-2">
            Control de facturación
          </h2>
          <p className="text-slate-500 font-bold">
            Colegios registrados, conductores y estudiantes por institución.
          </p>
        </div>
        <button
          type="button"
          onClick={exportExcel}
          disabled={!data?.companies?.length}
          className="bg-primary text-white px-8 py-4 rounded-2xl font-black uppercase text-xs tracking-widest hover:scale-105 transition-all disabled:opacity-50"
        >
          Exportar Excel
        </button>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-10">
        {[
          { label: 'Colegios', value: totals.companies, icon: 'corporate_fare' },
          { label: 'Conductores', value: totals.drivers, icon: 'directions_bus' },
          { label: 'Estudiantes', value: totals.students, icon: 'school' },
          { label: 'Activos', value: totals.studentsActive, icon: 'verified' },
        ].map((k) => (
          <div key={k.label} className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
            <span className="material-symbols-outlined text-primary text-2xl mb-2">{k.icon}</span>
            <p className="text-3xl font-black text-slate-900">{k.value}</p>
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{k.label}</p>
          </div>
        ))}
      </div>

      {fetching ? (
        <p className="text-slate-400 font-bold animate-pulse">Calculando métricas globales...</p>
      ) : (
        <div className="bg-white rounded-3xl overflow-hidden border border-slate-100 shadow-sm">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-100">
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Código</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Institución</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest">Admin / Correo</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Conductores</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Estudiantes</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Activos</th>
                <th className="px-6 py-5 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Pendientes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {(data?.companies || []).map((c) => (
                <tr key={c.unitCode} className="hover:bg-slate-50/80">
                  <td className="px-6 py-5 font-black text-primary">{c.unitCode}</td>
                  <td className="px-6 py-5 font-bold text-slate-800 uppercase">{c.name}</td>
                  <td className="px-6 py-5">
                    <p className="text-sm font-bold text-slate-700">{c.adminName || '—'}</p>
                    <p className="text-xs text-slate-400">{c.adminEmail || '—'}</p>
                  </td>
                  <td className="px-6 py-5 text-center font-black text-lg">{c.driversCount}</td>
                  <td className="px-6 py-5 text-center font-black text-lg">{c.studentsTotal}</td>
                  <td className="px-6 py-5 text-center font-bold text-emerald-600">{c.studentsActive}</td>
                  <td className="px-6 py-5 text-center font-bold text-amber-600">{c.studentsPending}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </DashboardLayout>
  );
}
