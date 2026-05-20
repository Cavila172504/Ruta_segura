import LandingPage from '@/components/landing/LandingPage';

export const metadata = {
  title: "Ruta Segura | Plataforma de Gestión Escolar",
  description: "Plataforma integral para colegios e instituciones. Controla rutas de transporte, monitoreo satelital en vivo y mejora la seguridad de tus estudiantes.",
  keywords: "software educativo, gestión escolar, sistema para colegios, transporte escolar, monitoreo gps",
  openGraph: {
    title: "Ruta Segura | Plataforma de Gestión Escolar",
    description: "Plataforma integral para colegios e instituciones. Control de rutas y monitoreo en tiempo real.",
    type: "website",
  }
};

export default function Home() {
  return <LandingPage />;
}
