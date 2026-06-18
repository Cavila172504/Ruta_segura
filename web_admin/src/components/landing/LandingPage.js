"use client";
import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { auth } from '@/lib/firebase';
import { signOut } from 'firebase/auth';
import DevCredit from '@/components/legal/DevCredit';
import BrandLogo from '@/components/ui/BrandLogo';

export default function LandingPage() {
  const router = useRouter();
  const { user, loading } = useAuth();
  const [scrolled, setScrolled] = useState(false);

  // Número de WhatsApp provisto por el usuario
  const WHATSAPP_NUMBER = "593963738659";
  const WHATSAPP_LINK = `https://wa.me/${WHATSAPP_NUMBER}?text=Hola,%20me%20gustar%C3%ADa%20recibir%20m%C3%A1s%20informaci%C3%B3n%20sobre%20RutaSegura%20para%20mi%20instituci%C3%B3n.`;

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleLoginClick = async () => {
    if (user) {
      try {
        await signOut(auth);
      } catch (error) {
        console.error('Error signing out', error);
      }
    }
    router.push('/login');
  };

  const scrollToSection = (id) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800">
      
      {/* ── BOTÓN FLOTANTE WHATSAPP ─────────────────────────────────────── */}
      <a 
        href={WHATSAPP_LINK} 
        target="_blank" 
        rel="noopener noreferrer"
        className="fixed bottom-6 right-6 z-50 bg-[#25D366] text-white p-4 rounded-full shadow-2xl hover:scale-105 transition-transform flex items-center justify-center"
      >
        {/* WhatsApp Icon SVG */}
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" fill="currentColor" viewBox="0 0 16 16">
          <path d="M13.601 2.326A7.854 7.854 0 0 0 7.994 0C3.627 0 .068 3.558.064 7.926c0 1.399.366 2.76 1.057 3.965L0 16l4.204-1.102a7.933 7.933 0 0 0 3.79.965h.004c4.368 0 7.926-3.558 7.93-7.93A7.898 7.898 0 0 0 13.6 2.326zM7.994 14.521a6.573 6.573 0 0 1-3.356-.92l-.24-.144-2.494.654.666-2.433-.156-.251a6.56 6.56 0 0 1-1.007-3.505c0-3.626 2.957-6.584 6.591-6.584a6.56 6.56 0 0 1 4.66 1.931 6.557 6.557 0 0 1 1.928 4.66c-.004 3.639-2.961 6.592-6.592 6.592zm3.615-4.934c-.197-.099-1.17-.578-1.353-.646-.182-.065-.315-.099-.445.099-.133.197-.513.646-.627.775-.114.133-.232.148-.43.05-.197-.1-.836-.308-1.592-.985-.59-.525-.985-1.175-1.103-1.372-.114-.198-.011-.304.088-.403.087-.088.197-.232.296-.346.1-.114.133-.198.198-.33.065-.134.034-.248-.015-.347-.05-.099-.445-1.076-.612-1.47-.16-.389-.323-.335-.445-.34-.114-.007-.247-.007-.38-.007a.729.729 0 0 0-.529.247c-.182.198-.691.677-.691 1.654 0 .977.71 1.916.81 2.049.098.133 1.394 2.132 3.383 2.992.47.205.84.326 1.129.418.475.152.904.129 1.246.08.38-.058 1.171-.48 1.338-.943.164-.464.164-.86.114-.943-.049-.084-.182-.133-.38-.232z"/>
        </svg>
      </a>

      {/* ── HEADER ──────────────────────────────────────────────────────── */}
      <header 
        className={`fixed top-0 w-full z-40 transition-all duration-300 ${
          scrolled ? 'bg-white/90 backdrop-blur-md shadow-sm py-3' : 'bg-transparent py-5'
        }`}
      >
        <div className="max-w-7xl mx-auto px-6 md:px-12 flex justify-between items-center">
          <div className="flex items-center gap-2 cursor-pointer" onClick={() => scrollToSection('hero')}>
            {/* Logo de la Empresa */}
            <BrandLogo className="h-10 md:h-12 w-auto object-contain" alt="Ruta Segura Logo" />
          </div>

          <nav className="hidden lg:flex items-center gap-8 font-bold text-sm text-slate-600">
            <button onClick={() => scrollToSection('ecosistema')} className="hover:text-primary transition-colors">Nuestro Ecosistema</button>
            <button onClick={() => scrollToSection('audiencia')} className="hover:text-primary transition-colors">¿Para quién?</button>
          </nav>

          <div className="flex items-center gap-4">
            <button 
              onClick={handleLoginClick}
              className="px-5 py-2 md:px-6 md:py-2.5 rounded-full bg-slate-900 text-white font-bold text-xs md:text-sm shadow-xl shadow-slate-900/20 hover:scale-105 hover:bg-primary transition-all duration-300 flex items-center gap-2"
            >
              {loading ? (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              ) : (
                <>
                  <span className="material-symbols-outlined text-sm">login</span>
                  <span className="hidden sm:inline">Acceso Administradores</span>
                  <span className="inline sm:hidden">Acceso</span>
                </>
              )}
            </button>
          </div>
        </div>
      </header>

      {/* ── HERO SECTION ────────────────────────────────────────────────── */}
      <section id="hero" className="relative pt-32 pb-20 md:pt-48 md:pb-32 overflow-hidden px-6">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full max-w-[1200px] z-0 pointer-events-none">
          <div className="absolute top-[20%] left-[-10%] w-[500px] h-[500px] bg-primary/20 rounded-full blur-[100px]"></div>
          <div className="absolute top-[10%] right-[-5%] w-[400px] h-[400px] bg-secondary/20 rounded-full blur-[100px]"></div>
        </div>

        <div className="max-w-7xl mx-auto relative z-10 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary font-bold text-xs mb-8 uppercase tracking-widest border border-primary/20 shadow-sm">
            <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
            Plataforma Integral de Transporte
          </div>
          
          <h1 className="text-5xl md:text-7xl font-headline font-black text-slate-900 leading-tight tracking-tight max-w-4xl mx-auto">
            El control total de tus unidades y la <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-secondary">tranquilidad de los padres</span>
          </h1>
          
          <p className="mt-8 text-lg md:text-xl text-slate-600 max-w-2xl mx-auto leading-relaxed">
            Ofrecemos tres soluciones conectadas en tiempo real: Una app para que los padres sientan seguridad, una herramienta ágil para conductores y un centro de mando para ti.
          </p>

          <div className="mt-12 flex flex-col sm:flex-row items-center justify-center gap-4">
            <a 
              href={WHATSAPP_LINK}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto px-8 py-4 rounded-full bg-[#25D366] text-white font-bold text-lg shadow-xl hover:scale-105 hover:bg-[#20bd5a] transition-all duration-300 flex items-center justify-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
                <path d="M13.601 2.326A7.854 7.854 0 0 0 7.994 0C3.627 0 .068 3.558.064 7.926c0 1.399.366 2.76 1.057 3.965L0 16l4.204-1.102a7.933 7.933 0 0 0 3.79.965h.004c4.368 0 7.926-3.558 7.93-7.93A7.898 7.898 0 0 0 13.6 2.326zM7.994 14.521a6.573 6.573 0 0 1-3.356-.92l-.24-.144-2.494.654.666-2.433-.156-.251a6.56 6.56 0 0 1-1.007-3.505c0-3.626 2.957-6.584 6.591-6.584a6.56 6.56 0 0 1 4.66 1.931 6.557 6.557 0 0 1 1.928 4.66c-.004 3.639-2.961 6.592-6.592 6.592zm3.615-4.934c-.197-.099-1.17-.578-1.353-.646-.182-.065-.315-.099-.445.099-.133.197-.513.646-.627.775-.114.133-.232.148-.43.05-.197-.1-.836-.308-1.592-.985-.59-.525-.985-1.175-1.103-1.372-.114-.198-.011-.304.088-.403.087-.088.197-.232.296-.346.1-.114.133-.198.198-.33.065-.134.034-.248-.015-.347-.05-.099-.445-1.076-.612-1.47-.16-.389-.323-.335-.445-.34-.114-.007-.247-.007-.38-.007a.729.729 0 0 0-.529.247c-.182.198-.691.677-.691 1.654 0 .977.71 1.916.81 2.049.098.133 1.394 2.132 3.383 2.992.47.205.84.326 1.129.418.475.152.904.129 1.246.08.38-.058 1.171-.48 1.338-.943.164-.464.164-.86.114-.943-.049-.084-.182-.133-.38-.232z"/>
              </svg>
              Contáctanos por WhatsApp
            </a>
            <button 
              onClick={() => scrollToSection('ecosistema')}
              className="w-full sm:w-auto px-8 py-4 rounded-full bg-white text-slate-700 font-bold text-lg border border-slate-200 shadow-sm hover:border-slate-300 hover:bg-slate-50 transition-all duration-300 flex items-center justify-center gap-2"
            >
              Conoce el Ecosistema
            </button>
          </div>
        </div>
      </section>

      {/* ── ECOSISTEMA (3 APLICACIONES) ─────────────────────────────────── */}
      <section id="ecosistema" className="py-24 bg-white relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 md:px-12">
          <div className="text-center max-w-3xl mx-auto mb-20">
            <h2 className="text-3xl md:text-5xl font-headline font-black text-slate-900 mb-6">
              El Ecosistema Perfecto
            </h2>
            <p className="text-slate-600 text-lg">
              No es solo un software, es una solución distribuida en tres potentes herramientas. Cada una diseñada específicamente para empoderar a cada actor del transporte escolar.
            </p>
          </div>

          {/* APP PADRE */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-32">
            <div className="order-2 lg:order-1 relative flex justify-center">
              <div className="absolute inset-0 bg-blue-100/50 rounded-[40px] transform rotate-3 scale-105"></div>
              <img 
                src="/images/parent_app_mockup.png" 
                alt="App Padre RutaSegura" 
                className="relative z-10 w-full max-w-[400px] rounded-[32px] shadow-2xl border-4 border-white object-cover"
              />
            </div>
            <div className="order-1 lg:order-2">
              <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center mb-6">
                <span className="material-symbols-outlined text-3xl">family_restroom</span>
              </div>
              <h3 className="text-3xl font-black text-slate-900 mb-4">App Padre:<br/>Tranquilidad en tus manos</h3>
              <p className="text-slate-600 text-lg leading-relaxed mb-6">
                Véndele a los padres de familia la paz mental que necesitan. Con nuestra aplicación exclusiva para representantes, podrán:
              </p>
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Monitorear la <strong>ubicación en tiempo real</strong> del recorrido de su hijo.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Recibir <strong>notificaciones automáticas</strong> cuando el bus esté cerca de la parada o haya llegado al colegio.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Seguridad absoluta: Solo padres vinculados tienen acceso al mapa de la ruta asignada.</span>
                </li>
              </ul>
            </div>
          </div>

          {/* APP CONDUCTOR */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-32">
            <div>
              <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center mb-6">
                <span className="material-symbols-outlined text-3xl">directions_bus</span>
              </div>
              <h3 className="text-3xl font-black text-slate-900 mb-4">App Conductor:<br/>Operación Simplificada</h3>
              <p className="text-slate-600 text-lg leading-relaxed mb-6">
                Diseñada para que el chofer se enfoque en conducir. Sin complicaciones técnicas.
              </p>
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Un botón central para <strong>iniciar y terminar la ruta</strong>. La app hace el resto.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Lista clara y legible de todos los estudiantes asignados a su viaje.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Reporte instantáneo de demoras o alertas que avisa a los padres y a la administración en 1 clic.</span>
                </li>
              </ul>
            </div>
            <div className="relative flex justify-center">
              <div className="absolute inset-0 bg-emerald-100/50 rounded-[40px] transform -rotate-3 scale-105"></div>
              <img 
                src="/images/driver_app_mockup.png" 
                alt="App Conductor RutaSegura" 
                className="relative z-10 w-full max-w-[400px] rounded-[32px] shadow-2xl border-4 border-white object-cover"
              />
            </div>
          </div>

          {/* PANEL ADMIN WEB */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div className="order-2 lg:order-1 relative flex justify-center">
              <div className="absolute inset-0 bg-primary/10 rounded-[40px] transform rotate-2 scale-105"></div>
              <img 
                src="/images/admin_dashboard_mockup.png" 
                alt="Panel Web Admin RutaSegura" 
                className="relative z-10 w-full rounded-2xl shadow-2xl border border-white/50 object-cover"
              />
            </div>
            <div className="order-1 lg:order-2">
              <div className="w-14 h-14 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mb-6">
                <span className="material-symbols-outlined text-3xl">admin_panel_settings</span>
              </div>
              <h3 className="text-3xl font-black text-slate-900 mb-4">Web Admin:<br/>Control Total para tu Empresa</h3>
              <p className="text-slate-600 text-lg leading-relaxed mb-6">
                Centraliza la logística de tu compañía de transporte o colegio desde cualquier computadora.
              </p>
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700"><strong>Mapa Global en Vivo:</strong> Visualiza todas tus unidades moviéndose al mismo tiempo.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Gestión de bases de datos: Conductores, vehículos, rutas y estudiantes vinculados.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-emerald-500 mt-0.5">check_circle</span>
                  <span className="text-slate-700">Identificación y alertas tempranas si un conductor sale de su ruta o se retrasa.</span>
                </li>
              </ul>
            </div>
          </div>

        </div>
      </section>

      {/* ── TARGET AUDIENCE ─────────────────────────────────────────────── */}
      <section id="audiencia" className="py-20 bg-slate-50">
        <div className="max-w-7xl mx-auto px-6 md:px-12 text-center">
          <h2 className="text-3xl md:text-4xl font-headline font-black text-slate-900 mb-12">
            Diseñado especialmente para
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {['Compañías de Transporte', 'Colegios Privados', 'Escuelas Públicas', 'Academias y Clubes'].map((title, i) => (
              <div key={i} className="bg-white py-8 px-6 rounded-2xl border border-slate-200 font-bold text-slate-700 hover:border-primary hover:text-primary transition-colors cursor-default shadow-sm">
                {title}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA FINAL (WHATSAPP) ───────────────────────────────────────── */}
      <section id="contacto" className="py-24 relative overflow-hidden">
        <div className="absolute inset-0 bg-slate-900 z-0"></div>
        <div className="absolute top-0 right-0 w-full h-full bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-5 pointer-events-none z-0"></div>
        
        <div className="max-w-4xl mx-auto px-6 relative z-10 text-center text-white">
          <h2 className="text-4xl md:text-5xl font-headline font-black leading-tight mb-6">
            Eleva el estándar de tu servicio de transporte escolar
          </h2>
          <p className="text-xl text-slate-300 mb-10 max-w-2xl mx-auto">
            Habla directamente con nosotros. Estaremos encantados de hacerte una demostración de cómo funcionan las 3 aplicaciones trabajando juntas.
          </p>
          
          <div className="flex flex-col items-center justify-center">
            <a 
              href={WHATSAPP_LINK}
              target="_blank"
              rel="noopener noreferrer"
              className="px-10 py-5 rounded-full bg-[#25D366] text-white font-black text-xl shadow-2xl hover:scale-105 hover:bg-[#20bd5a] transition-all duration-300 flex items-center justify-center gap-3 w-full sm:w-auto"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" fill="currentColor" viewBox="0 0 16 16">
                <path d="M13.601 2.326A7.854 7.854 0 0 0 7.994 0C3.627 0 .068 3.558.064 7.926c0 1.399.366 2.76 1.057 3.965L0 16l4.204-1.102a7.933 7.933 0 0 0 3.79.965h.004c4.368 0 7.926-3.558 7.93-7.93A7.898 7.898 0 0 0 13.6 2.326zM7.994 14.521a6.573 6.573 0 0 1-3.356-.92l-.24-.144-2.494.654.666-2.433-.156-.251a6.56 6.56 0 0 1-1.007-3.505c0-3.626 2.957-6.584 6.591-6.584a6.56 6.56 0 0 1 4.66 1.931 6.557 6.557 0 0 1 1.928 4.66c-.004 3.639-2.961 6.592-6.592 6.592zm3.615-4.934c-.197-.099-1.17-.578-1.353-.646-.182-.065-.315-.099-.445.099-.133.197-.513.646-.627.775-.114.133-.232.148-.43.05-.197-.1-.836-.308-1.592-.985-.59-.525-.985-1.175-1.103-1.372-.114-.198-.011-.304.088-.403.087-.088.197-.232.296-.346.1-.114.133-.198.198-.33.065-.134.034-.248-.015-.347-.05-.099-.445-1.076-.612-1.47-.16-.389-.323-.335-.445-.34-.114-.007-.247-.007-.38-.007a.729.729 0 0 0-.529.247c-.182.198-.691.677-.691 1.654 0 .977.71 1.916.81 2.049.098.133 1.394 2.132 3.383 2.992.47.205.84.326 1.129.418.475.152.904.129 1.246.08.38-.058 1.171-.48 1.338-.943.164-.464.164-.86.114-.943-.049-.084-.182-.133-.38-.232z"/>
              </svg>
              Escríbenos al WhatsApp
            </a>
            <p className="mt-6 text-slate-400 font-medium">Asistencia directa con nuestros fundadores: +593 96 373 8659</p>
          </div>
        </div>
      </section>

      {/* ── FOOTER ──────────────────────────────────────────────────────── */}
      <footer className="bg-slate-950 text-slate-400 py-12 border-t border-white/10">
        <div className="max-w-7xl mx-auto px-6 md:px-12 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-8">
          <div className="sm:col-span-2 lg:col-span-2">
            <div className="flex items-center gap-2 mb-4">
              <img 
                src="/images/logo.png" 
                alt="Ruta Segura Logo" 
                className="h-10 w-auto object-contain brightness-0 invert opacity-80"
              />
            </div>
            <p className="text-sm max-w-sm mt-4">
              Plataforma integral de transporte. Seguridad garantizada para las familias, y control operativo total para dueños de empresas de transporte.
            </p>
          </div>
          
          <div>
            <h4 className="text-white font-bold mb-4">Enlaces Rápidos</h4>
            <ul className="space-y-2 text-sm">
              <li><button onClick={() => scrollToSection('ecosistema')} className="hover:text-white transition-colors">Nuestro Ecosistema</button></li>
              <li><button onClick={() => scrollToSection('audiencia')} className="hover:text-white transition-colors">¿Para quién es?</button></li>
              <li><a href={WHATSAPP_LINK} target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">Contactar</a></li>
            </ul>
          </div>

          <div>
            <h4 className="text-white font-bold mb-4">Legal</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="/politica-seguridad" className="hover:text-white transition-colors">
                  Política de seguridad y ubicación
                </Link>
              </li>
              <li className="text-slate-500 text-xs leading-relaxed pt-1">
                Uso de GPS y rastreo en tiempo real para la seguridad del transporte escolar.
              </li>
            </ul>
          </div>

          <div>
            <h4 className="text-white font-bold mb-4">Acceso Institucional</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <button onClick={handleLoginClick} className="hover:text-white transition-colors flex items-center gap-2">
                  <span className="material-symbols-outlined text-sm">login</span>
                  Ingreso Administradores
                </button>
              </li>
            </ul>
          </div>
        </div>
        <div className="max-w-7xl mx-auto px-6 md:px-12 mt-12 pt-8 border-t border-white/5 text-xs flex flex-col md:flex-row justify-between items-center gap-4">
          <p>© {new Date().getFullYear()} RutaSegura. Todos los derechos reservados.</p>
          <div className="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-slate-500">
            <Link href="/politica-seguridad" className="hover:text-white transition-colors">
              Política de seguridad y ubicación
            </Link>
            <DevCredit />
          </div>
        </div>
      </footer>
    </div>
  );
}
