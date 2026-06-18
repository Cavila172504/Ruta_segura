"use client";

import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";
import { clearServerSession } from "@/lib/session-auth";

let redirectingToLogin = false;

async function handleUnauthorized() {
  if (redirectingToLogin || typeof window === "undefined") return;
  redirectingToLogin = true;
  try {
    await clearServerSession();
    await signOut(auth);
  } catch (error) {
    console.error("Error cerrando sesión tras 401:", error);
  }
  window.location.href = "/login?session=expired";
}

export async function authFetch(url, options = {}) {
  const user = auth.currentUser;
  if (!user) throw new Error("Sesión no iniciada");

  const token = await user.getIdToken();
  const headers = new Headers(options.headers || {});
  headers.set("Authorization", `Bearer ${token}`);
  if (options.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const response = await fetch(url, { ...options, headers });

  if (response.status === 401) {
    await handleUnauthorized();
    throw new Error("Sesión expirada");
  }

  return response;
}
