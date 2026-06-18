"use client";
import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { auth, db } from '@/lib/firebase';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { doc, getDoc } from 'firebase/firestore';
import { resolveOwnerLoginEmail, isOwnerLoginConfigured } from '@/lib/owner-login';
import { useIdleRedirect } from '@/hooks/useIdleRedirect';
import DevCredit from '@/components/legal/DevCredit';

const IDLE_TIMEOUT_MS = 3 * 60 * 1000;

const LoginPage = () => {
  const [loginInput, setLoginInput] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const [loginReadOnly, setLoginReadOnly] = useState(true);
  const [passwordReadOnly, setPasswordReadOnly] = useState(true);
  const router = useRouter();
  const ownerLoginEnabled = isOwnerLoginConfigured();

  useIdleRedirect({ timeoutMs: IDLE_TIMEOUT_MS, redirectTo: '/', enabled: !loading });

  useEffect(() => {
    setLoginInput('');
    setPassword('');
    const clearAutofill = setTimeout(() => {
      setLoginInput('');
      setPassword('');
    }, 100);
    return () => clearTimeout(clearAutofill);
  }, []);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const email = resolveOwnerLoginEmail(loginInput);
      const finalPassword = password.trim();

      if (!email.includes('@')) {
        setError(
          ownerLoginEnabled
            ? 'Ingresa tu correo corporativo o tu ID de propietario.'
            : 'Ingresa tu correo electrónico corporativo.'
        );
        setLoading(false);
        return;
      }

      const userCredential = await signInWithEmailAndPassword(auth, email, finalPassword);
      const uid = userCredential.user.uid;

      const adminRef = doc(db, "users", "admins", "members", uid);
      const adminSnap = await getDoc(adminRef);

      const superAdminRef = doc(db, "users", "super_admins", "members", uid);
      const superSnap = await getDoc(superAdminRef);

      if (adminSnap.exists() || superSnap.exists()) {
        const isSuper = superSnap.exists();
        router.push(isSuper ? '/dashboard/companies' : '/dashboard');
      } else {
        await auth.signOut();
        setError(
          "No tienes permisos de administrador. Ejecuta scripts/create-superuser.js para asignar rol super_admin."
        );
      }
    } catch (err) {
      setError("Credenciales incorrectas. Si eres propietario, verifica contraseña en Firebase (create-superuser.js).");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-6 relative">
      <button
        type="button"
        onClick={() => router.push('/')}
        className="absolute top-6 left-6 flex items-center gap-2 text-slate-500 hover:text-primary font-bold text-sm transition-colors"
        aria-label="Volver al inicio"
      >
        <span className="material-symbols-outlined text-xl">arrow_back</span>
        <span className="hidden sm:inline">Volver al inicio</span>
      </button>

      <div className="max-w-md w-full bg-surface-container-lowest rounded-3xl shadow-[0px_20px_60px_rgba(83,74,183,0.1)] overflow-hidden flex flex-col items-center p-10 border border-outline-variant/10">
        <div className="mb-8 text-center text-primary">
          <h1 className="text-3xl font-extrabold font-headline tracking-tight">RutaSegura</h1>
          <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mt-1">School Admin Access</p>
        </div>

        <form onSubmit={handleLogin} autoComplete="off" className="w-full space-y-6" data-lpignore="true" data-1p-ignore="true">
          <div className="space-y-2">
            <label htmlFor="admin-login-id" className="text-[12px] font-black text-slate-500 uppercase tracking-widest pl-1">
              {ownerLoginEnabled ? 'Correo o ID propietario' : 'Correo corporativo'}
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg">
                {ownerLoginEnabled ? 'person' : 'mail'}
              </span>
              <input
                id="admin-login-id"
                name="rutasegura-admin-id"
                type="text"
                required
                value={loginInput}
                readOnly={loginReadOnly}
                onFocus={() => setLoginReadOnly(false)}
                onChange={(e) => setLoginInput(e.target.value)}
                autoComplete="one-time-code"
                data-lpignore="true"
                data-1p-ignore="true"
                placeholder=""
                className="login-field w-full pl-12 pr-4 py-4 bg-slate-100 border-none rounded-2xl text-lg font-bold focus:ring-4 focus:ring-primary/10 transition-all outline-none"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="admin-login-pass" className="text-[12px] font-black text-slate-500 uppercase tracking-widest pl-1">Contraseña</label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg">lock</span>
              <input
                id="admin-login-pass"
                name="rutasegura-admin-pass"
                type="password"
                required
                value={password}
                readOnly={passwordReadOnly}
                onFocus={() => setPasswordReadOnly(false)}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="one-time-code"
                data-lpignore="true"
                data-1p-ignore="true"
                placeholder=""
                className="login-field w-full pl-12 pr-4 py-4 bg-slate-100 border-none rounded-2xl text-lg font-bold focus:ring-4 focus:ring-primary/10 transition-all outline-none"
              />
            </div>
          </div>

          {error && (
            <div className="bg-error-container/20 text-error text-xs font-bold p-3 rounded-xl border border-error/10 flex items-center gap-2">
              <span className="material-symbols-outlined text-sm">warning</span>
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary hover:bg-primary-container text-on-primary py-4 rounded-2xl font-bold text-sm transition-all shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] flex items-center justify-center gap-2 disabled:opacity-70"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
            ) : (
              <>
                Entrar al Panel
                <span className="material-symbols-outlined text-sm">login</span>
              </>
            )}
          </button>
        </form>

        <div className="mt-10 pt-10 border-t border-outline-variant/10 w-full text-center space-y-3">
          <p className="text-[10px] text-slate-400 font-medium">¿Olvidaste tu acceso? Contacta a Soporte Técnico</p>
          <p className="text-[10px] text-slate-400 leading-relaxed max-w-sm mx-auto">
            Al ingresar acepta el{' '}
            <Link href="/politica-seguridad" className="text-primary hover:underline font-bold">
              uso de ubicación y rastreo en tiempo real
            </Link>{' '}
            de RutaSegura.
          </p>
          <DevCredit />
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
