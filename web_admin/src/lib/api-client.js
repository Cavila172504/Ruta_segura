'use client';

import { auth } from '@/lib/firebase';

export async function authFetch(url, options = {}) {
  const user = auth.currentUser;
  if (!user) throw new Error('Sesion no iniciada');

  const token = await user.getIdToken();
  const headers = new Headers(options.headers || {});
  headers.set('Authorization', `Bearer ${token}`);
  if (options.body && !headers.has('Content-Type')) headers.set('Content-Type', 'application/json');
  return fetch(url, { ...options, headers });
}