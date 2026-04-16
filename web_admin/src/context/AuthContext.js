"use client";
import { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";

const AuthContext = createContext({});

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeUnitCode, _setActiveUnitCode] = useState(null);

  const setActiveUnitCode = (code) => {
    _setActiveUnitCode(code);
    localStorage.setItem('activeUnitCode', code);
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        setUser(user);
        // Buscar perfil en Firestore (admins, drivers, parents)
        const adminRef = doc(db, "users", "admins", "members", user.uid);
        const adminSnap = await getDoc(adminRef);

        if (adminSnap.exists()) {
          const data = adminSnap.data();
          setProfile({ ...data, role: "admin" });
          _setActiveUnitCode(data.unitCode);
        } else {
          // Si no es admin, quizás es un super_admin
          const superAdminRef = doc(db, "users", "super_admins", "members", user.uid);
          const superSnap = await getDoc(superAdminRef);
          if (superSnap.exists()) {
            setProfile({ ...superSnap.data(), role: "super_admin" });
            const saved = localStorage.getItem('activeUnitCode');
            _setActiveUnitCode(saved || 'CAD31'); // Default al primer colegio o global
          } else {
            setProfile(null);
          }
        }
      } else {
        setUser(null);
        setProfile(null);
        _setActiveUnitCode(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const SCHOOL_CODE = profile?.role === 'super_admin' ? activeUnitCode : profile?.unitCode;

  return (
    <AuthContext.Provider value={{ user, profile, loading, activeUnitCode, setActiveUnitCode, SCHOOL_CODE }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
