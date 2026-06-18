export default function ResponsiveTable({ children, className = "" }) {
  return (
    <div className={`bg-white rounded-3xl overflow-hidden border border-slate-100 shadow-sm ${className}`}>
      <div className="overflow-x-auto">{children}</div>
    </div>
  );
}