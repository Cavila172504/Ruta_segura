export default function KpiCard({ label, value, subtitle, icon, accent = 'blue', trend }) {
  const accents = {
    blue: { bar: 'bg-blue-500', icon: 'bg-blue-50 text-blue-600', spark: 'from-blue-400/40 to-blue-500/10' },
    teal: { bar: 'bg-teal-500', icon: 'bg-teal-50 text-teal-600', spark: 'from-teal-400/40 to-teal-500/10' },
    green: { bar: 'bg-emerald-500', icon: 'bg-emerald-50 text-emerald-600', spark: 'from-emerald-400/40 to-emerald-500/10' },
    amber: { bar: 'bg-amber-500', icon: 'bg-amber-50 text-amber-600', spark: 'from-amber-400/40 to-amber-500/10' },
    violet: { bar: 'bg-violet-500', icon: 'bg-violet-50 text-violet-600', spark: 'from-violet-400/40 to-violet-500/10' },
    rose: { bar: 'bg-rose-500', icon: 'bg-rose-50 text-rose-600', spark: 'from-rose-400/40 to-rose-500/10' },
  };
  const a = accents[accent] || accents.blue;
  const strokeColors = {
    blue: '#3b82f6', teal: '#14b8a6', green: '#10b981', amber: '#f59e0b', violet: '#8b5cf6', rose: '#f43f5e',
  };
  const stroke = strokeColors[accent] || strokeColors.blue;

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex flex-col justify-between min-h-[132px] hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">{label}</p>
          <p className="text-3xl font-black text-slate-900 mt-1 leading-none tracking-tight">{value}</p>
          {subtitle && <p className="text-xs text-slate-500 font-medium mt-1.5">{subtitle}</p>}
        </div>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ${a.icon}`}>
          <span className="material-symbols-outlined text-[22px]">{icon}</span>
        </div>
      </div>
      <div className="mt-4 h-8 rounded-lg bg-slate-50 overflow-hidden relative">
        <div className={`absolute inset-0 bg-gradient-to-r ${a.spark} opacity-80`} />
        <svg viewBox="0 0 120 32" className="w-full h-full opacity-60" preserveAspectRatio="none">
          <polyline fill="none" stroke={stroke} strokeWidth="2" points={trend || '0,24 20,18 40,22 60,12 80,16 100,8 120,14'} />
        </svg>
      </div>
    </div>
  );
}
