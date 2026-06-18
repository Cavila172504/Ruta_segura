export default function BillingStatusBadge({ status = "active" }) {
  const styles = {
    active: "bg-emerald-50 text-emerald-700 border-emerald-200",
    trial: "bg-sky-50 text-sky-700 border-sky-200",
    suspended: "bg-amber-50 text-amber-800 border-amber-200",
    cancelled: "bg-rose-50 text-rose-700 border-rose-200",
  };
  const labels = {
    active: "Activo",
    trial: "Prueba",
    suspended: "Suspendido",
    cancelled: "Cancelado",
  };
  const tone = styles[status] || styles.active;
  const label = labels[status] || status;
  return (
    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-black uppercase border ${tone}`}>
      {label}
    </span>
  );
}