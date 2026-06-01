"use client";
import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';

const DEFAULT_EVENTS = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];

/**
 * Redirige tras inactividad prolongada (p. ej. pantalla de login publica).
 */
export function useIdleRedirect({ timeoutMs = 180000, redirectTo = '/', enabled = true } = {}) {
  const router = useRouter();
  const timerRef = useRef(null);

  useEffect(() => {
    if (!enabled) return;

    const resetTimer = () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(() => {
        router.replace(redirectTo);
      }, timeoutMs);
    };

    DEFAULT_EVENTS.forEach((event) => {
      window.addEventListener(event, resetTimer, { passive: true });
    });

    resetTimer();

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      DEFAULT_EVENTS.forEach((event) => {
        window.removeEventListener(event, resetTimer);
      });
    };
  }, [timeoutMs, redirectTo, enabled, router]);
}
