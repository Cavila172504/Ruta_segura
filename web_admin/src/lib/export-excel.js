import * as XLSX from 'xlsx';

/** Exporta datos a formato Excel clásico (.xls) compatible con Microsoft Excel. */
export function exportToXls(rows, fileName, sheetName = 'Reporte') {
  if (!rows?.length) return false;
  const ws = XLSX.utils.json_to_sheet(rows);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, sheetName);
  const safeName = (fileName || 'reporte').replace(/\.xlsx?$/i, '');
  XLSX.writeFile(wb, `${safeName}.xls`, { bookType: 'biff8' });
  return true;
}

export function mergeDriverOptions(companyDrivers = [], routes = [], students = []) {
  const map = new Map();

  const put = (id, data) => {
    if (!id) return;
    map.set(id, { id, ...map.get(id), ...data, id });
  };

  companyDrivers.forEach((d) => put(d.id, d));

  routes.forEach((r) => {
    if (!r.driverId) return;
    const parts = (r.entryDriver || '').trim().split(/\s+/);
    put(r.driverId, {
      name: r.entryDriver || map.get(r.driverId)?.name,
      names: map.get(r.driverId)?.names || parts[0] || '',
      lastNames: map.get(r.driverId)?.lastNames || parts.slice(1).join(' ') || '',
    });
  });

  students.forEach((s) => {
    if (!s.driverId) return;
    if (!map.has(s.driverId)) {
      put(s.driverId, { name: 'Conductor asignado', names: 'Conductor' });
    }
  });

  return Array.from(map.values()).sort((a, b) => {
    const na = `${a.names || ''} ${a.lastNames || ''} ${a.name || ''}`.trim();
    const nb = `${b.names || ''} ${b.lastNames || ''} ${b.name || ''}`.trim();
    return na.localeCompare(nb, 'es');
  });
}

export function driverDisplayName(d) {
  if (!d) return 'Conductor';
  const full = `${d.names || ''} ${d.lastNames || ''}`.trim();
  return full || d.name || `Conductor ${(d.id || '').slice(0, 6)}`;
}
