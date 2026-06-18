import { NextResponse } from "next/server";
import { SESSION_COOKIE_NAME } from "@/lib/session-constants";

export function middleware(request) {
  const { pathname } = request.nextUrl;

  if (!pathname.startsWith("/dashboard")) {
    return NextResponse.next();
  }

  const session = request.cookies.get(SESSION_COOKIE_NAME);
  if (!session?.value) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("from", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*"],
};