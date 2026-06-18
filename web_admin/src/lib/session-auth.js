import { SESSION_COOKIE_NAME } from "@/lib/session-constants";

export { SESSION_COOKIE_NAME };

export async function setServerSession(idToken) {
  const res = await fetch("/api/auth/session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || "No se pudo iniciar la sesion del servidor");
  }
}

export async function clearServerSession() {
  await fetch("/api/auth/session", { method: "DELETE" });
}