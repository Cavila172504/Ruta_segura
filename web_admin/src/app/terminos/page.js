import Link from 'next/link';
import { legalContent } from '@/content/legal/es';

export const metadata = {
  title: 'Terminos y Condiciones | RutaSegura',
};

export default function TerminosPage() {
  return (
    <main className="min-h-screen bg-slate-50 text-slate-800">
      <div className="max-w-3xl mx-auto px-6 py-16">
        <Link href="/" className="text-primary font-bold text-sm hover:underline">
          Volver al inicio
        </Link>
        <h1 className="text-4xl font-black mt-8 mb-6">{legalContent.termsTitle}</h1>
        <article className="prose prose-slate max-w-none whitespace-pre-line leading-relaxed">
          {legalContent.termsBody}
        </article>
      </div>
    </main>
  );
}