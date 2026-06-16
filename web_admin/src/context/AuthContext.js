"use client";
import { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";

const AuthContext = createContext({});

const normalizeUnitCode = (code) => {
  const normalized = code?.trim().toUpperCase();
  return normalized || null;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeUnitCode, _setActiveUnitCode] = useState(null);
  const [activeUnitName, _setActiveUnitName] = useState(null);

  const setActiveUnitCode = (code, name = null) => {
    const normalized = normalizeUnitCode(code);
    _setActiveUnitCode(normalized);
    if (typeof window !== "undefined") {
      if (normalized) {
        localStorage.setItem("activeUnitCode", normalized);
      } else {
        localStorage.removeItem("activeUnitCode");
      }
      if (name) {
        localStorage.setItem("activeUnitName", name);
        _setActiveUnitName(name);
      }
    }
  };

  const clearSupportContext = () => {
    _setActiveUnitCode(null);
    _setActiveUnitName(null);
    if (typeof window !== "undefined") {
      localStorage.removeItem("activeUnitCode");
      localStorage.removeItem("activeUnitName");
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        setUser(firebaseUser);

        try {
          const superAdminRef = doc(
            db,
            "users",
            "super_admins",
            "members",
            firebaseUser.uid
          );
          const superSnap = await getDoc(superAdminRef);

          if (superSnap.exists()) {
            setProfile({ ...superSnap.data(), role: "super_admin" });
            if (typeof window !== "undefined") {
              const savedCode = localStorage.getItem("activeUnitCode");
              const savedName = localStorage.getItem("activeUnitName");
              if (savedCode) _setActiveUnitCode(normalizeUnitCode(savedCode));
              if (savedName) _setActiveUnitName(savedName);
            }
            return;
          }

          const adminRef = doc(db, "users", "admins", "members", firebaseUser.uid);
          const adminSnap = await getDoc(adminRef);

          if (adminSnap.exists()) {
            const data = adminSnap.data();
            setProfile({
              ...data,
              role: data.role || "admin",
              unitCode: normalizeUnitCode(data.unitCode),
            });
            setActiveUnitCode(data.unitCode);
          } else {
            setProfile(null);
          }
        } catch (err) {
          console.error("AuthContext: error cargando perfil admin", err);
          setProfile(null);
          if (err?.code === "permission-denied") {
            await signOut(auth);
            setUser(null);
            clearSupportContext();
          }
        }
      } else {
        setUser(null);
        setProfile(null);
        _setActiveUnitCode(null);
        _setActiveUnitName(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const SCHOOL_CODE =
    profile?.role === "super_admin"
      ? activeUnitCode
      : normalizeUnitCode(profile?.unitCode);

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        loading,
        activeUnitCode,
        activeUnitName,
        setActiveUnitCode,
        clearSupportContext,
        SCHOOL_CODE,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
