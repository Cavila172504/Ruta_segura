export default function LiveRoutesPanel({ rows, onSelect }) {
  return (
    <div className="absolute bottom-4 right-4 z-[1000] w-[min(100%,340px)] bg-white/95 backdrop-blur-md rounded-2xl shadow-xl border border-slate-200/80 overflow-hidden">
      <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
        <h4 className="text-xs font-black text-slate-800 uppercase tracking-widest">Rutas en vivo</h4>
        <span className="text-[10px] font-bold text-emerald-600 flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
          LIVE
        </span>
      </div>
      <div className="max-h-[220px] overflow-y-auto">
        {rows.length === 0 ? (
          <p className="text-xs text-slate-400 italic p-4 text-center">Sin unidades activas ahora</p>
        ) : (
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 sticky top-0">
              <tr>
                <th className="px-3 py-2 font-black text-slate-400 uppercase text-[9px]">Ruta / Unidad</th>
                <th className="px-3 py-2 font-black text-slate-400 uppercase text-[9px] text-center">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {rows.map((row) => (
                <tr
                  key={row.id}
                  className="hover:bg-blue-50/50 cursor-pointer transition-colors"
                  onClick={() => onSelect?.(row.id)}
                >
                  <td className="px-3 py-2.5">
                    <p className="font-black text-slate-800">{row.label}</p>
                    <p className="text-[10px] text-slate-400 truncate max-w-[180px]">{row.driverName}</p>
                  </td>
                  <td className="px-3 py-2.5 text-center">
                    <span
                      className={`inline-block px-2 py-0.5 rounded-full text-[9px] font-black uppercase ${
                        row.status === 'on_time'
                          ? 'bg-emerald-100 text-emerald-700'
                          : row.status === 'delay'
                            ? 'bg-amber-100 text-amber-700'
                            : row.status === 'alert'
                              ? 'bg-rose-100 text-rose-700'
                              : 'bg-slate-100 text-slate-500'
                      }`}
                    >
                      {row.statusLabel}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
