"use client";
import React from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';

const ReportsPage = () => {
  return (
    <DashboardLayout title="Informes y Reportes">
      <div className="mb-10 flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h1 className="text-4xl font-extrabold tracking-tight text-on-surface mb-2">Informes y Reportes</h1>
          <p className="text-on-surface-variant text-sm font-medium">Análisis detallado del rendimiento de rutas y asistencia estudiantil.</p>
        </div>
        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-[0px_10px_30px_rgba(83,74,183,0.03)] flex flex-wrap items-end gap-4 border border-outline-variant/10">
          <div className="flex flex-col gap-1.5">
            <label className="text-[10px] font-bold uppercase tracking-widest text-outline">Rango de Fecha</label>
            <div className="flex items-center gap-2">
              <input type="date" className="bg-surface-container-low border-none rounded-lg text-sm px-3 py-2 focus:ring-2 focus:ring-primary" />
              <span className="text-outline text-xs">a</span>
              <input type="date" className="bg-surface-container-low border-none rounded-lg text-sm px-3 py-2 focus:ring-2 focus:ring-primary" />
            </div>
          </div>
          <button className="bg-primary text-white px-6 py-2.5 rounded-lg font-bold text-sm hover:opacity-90 transition-all flex items-center gap-2 shadow-lg shadow-primary/20">
            <span className="material-symbols-outlined text-sm">refresh</span>
            Generar Reporte
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {/* Metric Cards */}
        {[
          { label: 'Total de Viajes', value: '1,284', change: '+12%', icon: 'directions_bus', color: 'bg-primary' },
          { label: 'Asistencia Promedio', value: '94.2%', change: '+3%', icon: 'group', color: 'bg-secondary' },
          { label: 'Incidentes Totales', value: '03', change: '-50%', icon: 'warning', color: 'bg-error' },
        ].map((stat) => (
          <div key={stat.label} className="bg-surface-container-lowest p-6 rounded-xl relative overflow-hidden group shadow-sm border border-outline-variant/5">
            <div className={`absolute top-0 left-0 w-1 h-full ${stat.color}`}></div>
            <p className="text-[10px] font-extrabold text-outline uppercase tracking-widest mb-1">{stat.label}</p>
            <div className="flex items-end gap-2">
              <span className="text-4xl font-extrabold text-on-surface tracking-tighter">{stat.value}</span>
              <span className={`text-xs font-bold ${stat.change.startsWith('+') ? 'text-emerald-600' : 'text-rose-600'} mb-1 flex items-center`}>
                <span className="material-symbols-outlined text-xs">{stat.change.startsWith('+') ? 'arrow_upward' : 'arrow_downward'}</span>
                {stat.change}
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-surface-container-lowest p-8 rounded-2xl shadow-[0px_10px_30px_rgba(0,0,0,0.02)] border border-outline-variant/5">
          <div className="flex justify-between items-center mb-8">
            <h3 className="text-lg font-bold text-on-surface">Asistencia Mensual</h3>
          </div>
          <div className="h-64 flex items-end justify-between gap-2 relative">
            <div className="absolute inset-0 flex flex-col justify-between py-2 pointer-events-none opacity-10">
              <div className="border-b border-outline w-full"></div>
              <div className="border-b border-outline w-full"></div>
              <div className="border-b border-outline w-full"></div>
              <div className="border-b border-outline w-full"></div>
            </div>
            {['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN'].map((mes, idx) => (
              <div key={mes} className="flex-1 flex flex-col items-center group z-10">
                <div className="w-full bg-surface-container-low rounded-t-lg h-32 relative">
                  <div className="absolute bottom-0 w-full bg-primary-container rounded-t-lg transition-all group-hover:bg-primary" style={{ height: `${70 + idx * 5}%` }}></div>
                </div>
                <span className="text-[10px] mt-3 font-bold text-outline">{mes}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="flex flex-col gap-6">
          <div className="bg-surface-container-lowest p-8 rounded-2xl flex-1 flex flex-col justify-center border-l-4 border-tertiary-fixed shadow-sm border border-outline-variant/5">
            <h3 className="text-lg font-bold text-on-surface mb-6">Exportar Datos</h3>
            <div className="flex flex-col gap-4">
              <button className="w-full py-4 px-6 bg-surface-container-low hover:bg-surface-container-high rounded-xl flex items-center justify-between transition-all group">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-error/10 text-error rounded-lg flex items-center justify-center">
                    <span className="material-symbols-outlined">picture_as_pdf</span>
                  </div>
                  <div className="text-left">
                    <p className="text-sm font-bold text-on-surface">Descargar PDF</p>
                    <p className="text-[10px] text-outline font-medium">Informe detallado visual</p>
                  </div>
                </div>
                <span className="material-symbols-outlined text-outline group-hover:translate-x-1 transition-transform">download</span>
              </button>
              <button className="w-full py-4 px-6 bg-surface-container-low hover:bg-surface-container-high rounded-xl flex items-center justify-between transition-all group">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-emerald-100 text-emerald-600 rounded-lg flex items-center justify-center">
                    <span className="material-symbols-outlined">table_chart</span>
                  </div>
                  <div className="text-left">
                    <p className="text-sm font-bold text-on-surface">Descargar Excel</p>
                    <p className="text-[10px] text-outline font-medium">Hoja de cálculo de datos crudos</p>
                  </div>
                </div>
                <span className="material-symbols-outlined text-outline group-hover:translate-x-1 transition-transform">download</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default ReportsPage;
