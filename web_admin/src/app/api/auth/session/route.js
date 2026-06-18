import { NextResponse } from "next/server";
import { adminAuth, isAdminInitialized } from "@/lib/firebase-admin";
import { SESSION_COOKIE_NAME } from "@/lib/session-constants";

const SESSION_EXPIRES_MS = 60 * 60 * 24 * 5 * 1000;

export async function POST(request) {
  if (!isAdminInitialized() || !adminAuth) {
    return NextResponse.json(
      { error: "Firebase Admin no configurado en el servidor" },
      { status: 503 },
    );
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Cuerpo JSON invalido" }, { status: 400 });
  }

  const idToken = body?.idToken?.trim();
  if (!idToken) {
    return NextResponse.json({ error: "Token requerido" }, { status: 400 });
  }

  try {
    const sessionCookie = await adminAuth.createSessionCookie(idToken, {
      expiresIn: SESSION_EXPIRES_MS,
    });
    const response = NextResponse.json({ ok: true });
    response.cookies.set(SESSION_COOKIE_NAME, sessionCookie, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: Math.floor(SESSION_EXPIRES_MS / 1000),
      path: "/",
    });
    return response;
  } catch (error) {
    console.error("Error creando session cookie:", error);
    return NextResponse.json({ error: "Token invalido o expirado" }, { status: 401 });
  }
}

export async function DELETE() {
  const response = NextResponse.json({ ok: true });
  response.cookies.set(SESSION_COOKIE_NAME, "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 0,
    path: "/",
  });
  return response;
}