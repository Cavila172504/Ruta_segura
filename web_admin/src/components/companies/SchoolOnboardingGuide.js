export default function SchoolOnboardingGuide({ compact = false }) {
  const steps = [
    { icon: "tag", title: "1. Codigo del colegio", text: "Tu defines el codigo unico (ej. CAD32). Los padres lo ingresan en la app para vincular su colegio." },
    { icon: "location_on", title: "2. Ubicacion en mapa", text: "Busca la direccion o el nombre del colegio. Tambien puedes arrastrar el pin en el mapa." },
    { icon: "admin_panel_settings", title: "3. Acceso del administrador", text: "Correo y contraseña para que el colegio gestione conductores, rutas e inscripciones." },
    { icon: "family_restroom", title: "4. Padres en la app", text: "Comparte el codigo con las familias. Ellas registran al alumno y el colegio aprueba en Inscripciones." },
  ];
  return (
    <div className={`rounded-2xl border border-primary/15 bg-primary/5 ${compact ? "p-4" : "p-5"}`}>
      <p className="text-[10px] font-black uppercase tracking-widest text-primary mb-3">Flujo de negocio RutaSegura</p>
      <div className={`grid gap-3 ${compact ? "grid-cols-1" : "grid-cols-1 md:grid-cols-2"}`}>
        {steps.map((step) => (
          <div key={step.title} className="flex gap-3 items-start">
            <span className="material-symbols-outlined text-primary text-lg shrink-0">{step.icon}</span>
            <div>
              <p className="text-xs font-black text-slate-800">{step.title}</p>
              <p className="text-[11px] text-slate-600 leading-snug mt-0.5">{step.text}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}