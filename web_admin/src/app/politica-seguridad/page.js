import Link from 'next/link';
import SecurityPolicyContent from '@/components/legal/SecurityPolicyContent';
import DevCredit from '@/components/legal/DevCredit';

export const metadata = {
  title: 'Política de Seguridad y Ubicación | RutaSegura',
  description: 'Uso de ubicación y rastreo en tiempo real en la plataforma RutaSegura.',
};

export default function PoliticaSeguridadPage() {
  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white border-b border-slate-200 sticky top-0 z-10">
        <div className="max-w-3xl mx-auto px-6 py-4 flex items-center justify-between gap-4">
          <Link href="/" className="flex items-center gap-2 text-sm font-bold text-slate-600 hover:text-primary">
            <span className="material-symbols-outlined text-base">arrow_back</span>
            Volver al inicio
          </Link>
          <img src="/images/logo.png" alt="RutaSegura" className="h-8 w-auto" />
        </div>
      </header>

      <main className="max-w-3xl mx-auto px-6 py-12">
        <h1 className="text-3xl md:text-4xl font-black text-slate-900 uppercase tracking-tight mb-2">
          Política de Seguridad
        </h1>
        <p className="text-slate-500 font-medium mb-10">Ubicación, rastreo en tiempo real y protección de datos</p>
        <SecurityPolicyContent />
      </main>

      <footer className="border-t border-slate-200 py-8 text-center">
        <p className="text-xs text-slate-400">
          © {new Date().getFullYear()} RutaSegura ·{' '}
          <Link href="/politica-seguridad" className="hover:text-primary">
            Política de seguridad
          </Link>
        </p>
        <div className="mt-2">
          <DevCredit />
        </div>
      </footer>
    </div>
  );
}
