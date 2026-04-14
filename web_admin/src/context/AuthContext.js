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

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        setUser(user);
        // Buscar perfil en Firestore (admins, drivers, parents)
        // Nota: Para el admin central, buscamos en /users/admins/members/{uid}
        const adminRef = doc(db, "users", "admins", "members", user.uid);
        const adminSnap = await getDoc(adminRef);

        if (adminSnap.exists()) {
          setProfile({ ...adminSnap.data(), role: "admin" });
        } else {
          // Si no es admin, quizás es un super_admin
          const superAdminRef = doc(db, "users", "super_admins", "members", user.uid);
          const superSnap = await getDoc(superAdminRef);
          if (superSnap.exists()) {
            setProfile({ ...superSnap.data(), role: "super_admin" });
          } else {
            setProfile(null);
          }
        }
      } else {
        setUser(null);
        setProfile(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, profile, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
