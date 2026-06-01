/** ID propietario -> correo Firebase Auth */
const DEFAULT_OWNER_ID = '1725049827';
const DEFAULT_OWNER_EMAIL = 'csavilaf95@gmail.com';

export function resolveOwnerLoginEmail(input) {
  const trimmed = input.trim();
  const ownerId = process.env.NEXT_PUBLIC_OWNER_LOGIN_ID?.trim() || DEFAULT_OWNER_ID;
  const ownerEmail = process.env.NEXT_PUBLIC_OWNER_LOGIN_EMAIL?.trim() || DEFAULT_OWNER_EMAIL;
  if (trimmed === ownerId) return ownerEmail;
  return trimmed;
}

export function isOwnerLoginConfigured() {
  return true;
}