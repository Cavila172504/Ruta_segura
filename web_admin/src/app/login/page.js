"use client";
import React, { useState } from 'react';
import { auth, db } from '@/lib/firebase';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { doc, getDoc } from 'firebase/firestore';

const LoginPage = () => {
  const [loginInput, setLoginInput] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const trimmedInput = loginInput.trim();
      const trimmedPassword = password.trim();
      
      let finalEmail = trimmedInput;
      let finalPassword = trimmedPassword;

      // Acceso Especial Super Usuario
      if (trimmedInput === '1725049827') {
        finalEmail = 'csavilaf95@gmail.com';
      }

      const userCredential = await signInWithEmailAndPassword(auth, finalEmail, finalPassword);
      const uid = userCredential.user.uid;

      // Verificar si es admin
      const adminRef = doc(db, "users", "admins", "members", uid);
      const adminSnap = await getDoc(adminRef);

      const superAdminRef = doc(db, "users", "super_admins", "members", uid);
      const superSnap = await getDoc(superAdminRef);

      if (adminSnap.exists() || superSnap.exists()) {
        router.push('/dashboard');
      } else {
        await auth.signOut();
        setError("No tienes permisos de administrador.");
      }
    } catch (err) {
      setError("Credenciales incorrectas. Por favor intenta de nuevo.");
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-surface-container-lowest rounded-3xl shadow-[0px_20px_60px_rgba(83,74,183,0.1)] overflow-hidden flex flex-col items-center p-10 border border-outline-variant/10">
        <div className="mb-8 text-center text-primary">
          <h1 className="text-3xl font-extrabold font-headline tracking-tight">RutaSegura</h1>
          <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mt-1">School Admin Access</p>
        </div>

        <form onSubmit={handleLogin} className="w-full space-y-6">
          <div className="space-y-2">
            <label className="text-[12px] font-black text-slate-500 uppercase tracking-widest pl-1">Usuario / Email Corporativo</label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg">person</span>
              <input 
                type="text" 
                required
                value={loginInput}
                onChange={(e) => setLoginInput(e.target.value)}
                placeholder="ID o Correo"
                className="w-full pl-12 pr-4 py-4 bg-slate-100 border-none rounded-2xl text-lg font-bold focus:ring-4 focus:ring-primary/10 transition-all outline-none"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-[12px] font-black text-slate-500 uppercase tracking-widest pl-1">Contraseña</label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg">lock</span>
              <input 
                type="password" 
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-12 pr-4 py-4 bg-slate-100 border-none rounded-2xl text-lg font-bold focus:ring-4 focus:ring-primary/10 transition-all outline-none"
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

        <div className="mt-10 pt-10 border-t border-outline-variant/10 w-full text-center">
          <p className="text-[10px] text-slate-400 font-medium">¿Olvidaste tu acceso? Contacta a Soporte Técnico</p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
