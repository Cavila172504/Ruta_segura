export default function SecurityPolicyContent() {
  return (
    <div className="prose prose-slate max-w-none text-slate-600 text-sm leading-relaxed space-y-6">
      <p className="text-base text-slate-700">
        RutaSegura utiliza servicios de <strong>ubicación y rastreo en tiempo real</strong> para operar el transporte escolar de forma segura. Esta política explica cómo se usan esos datos en la app de padres, la app de conductores y el panel administrativo.
      </p>

      <section>
        <h2 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-2">1. Finalidad del rastreo</h2>
        <ul className="list-disc pl-5 space-y-1">
          <li>Mostrar a los padres el avance del bus asignado a su hijo durante el recorrido activo.</li>
          <li>Permitir a la institución o cooperativa supervisar unidades en ruta desde el panel web.</li>
          <li>Registrar asistencia, incidentes operativos (velocidad, retrasos) y alertas de seguridad.</li>
          <li>Calcular tiempos estimados de llegada y notificar aproximación a paradas.</li>
        </ul>
      </section>

      <section>
        <h2 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-2">2. Quién accede a la ubicación</h2>
        <ul className="list-disc pl-5 space-y-1">
          <li><strong>Conductores:</strong> la app captura GPS solo mientras el recorrido está iniciado.</li>
          <li><strong>Padres vinculados:</strong> ven la unidad de la ruta donde está inscrito su representado; no acceden a otras rutas.</li>
          <li><strong>Administradores autorizados:</strong> monitorean la flota de su institución desde el panel web.</li>
          <li>No vendemos ni compartimos ubicación con terceros ajenos al servicio contratado.</li>
        </ul>
      </section>

      <section>
        <h2 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-2">3. Permisos en el dispositivo</h2>
        <p>
          Las aplicaciones móviles solicitan permiso de <strong>ubicación</strong> (y notificaciones, cuando aplique) para habilitar el mapa en vivo, las alertas y la operación del conductor. Puede revocar permisos desde los ajustes del teléfono; sin ubicación activa el rastreo en tiempo real no funcionará.
        </p>
      </section>

      <section>
        <h2 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-2">4. Conservación de datos</h2>
        <p>
          La posición en vivo se actualiza durante el viaje y deja de publicarse al finalizar el recorrido. Los registros de asistencia e incidentes se conservan para informes institucionales según la configuración operativa de cada colegio.
        </p>
      </section>

      <section>
        <h2 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-2">5. Seguridad</h2>
        <p>
          El acceso está protegido por autenticación Firebase, reglas de Firestore por rol (padre, conductor, administrador) y vinculación verificada entre representantes y estudiantes. Solo usuarios autorizados pueden consultar datos de una unidad educativa.
        </p>
      </section>

      <section>
        <h2 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-2">6. Aceptación</h2>
        <p>
          Al usar RutaSegura usted acepta este tratamiento de ubicación y rastreo con fines de seguridad del transporte escolar. Para consultas:{' '}
          <a href="https://wa.me/593963738659" className="text-primary font-bold hover:underline" target="_blank" rel="noopener noreferrer">
            +593 96 373 8659
          </a>.
        </p>
        <p className="text-xs text-slate-400 mt-4">Última actualización: junio 2026.</p>
      </section>
    </div>
  );
}
