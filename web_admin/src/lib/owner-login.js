/** ID propietario -> correo Firebase Auth (solo via variables de entorno) */
export function resolveOwnerLoginEmail(input) {
  const trimmed = input.trim();
  const ownerId = process.env.NEXT_PUBLIC_OWNER_LOGIN_ID?.trim();
  const ownerEmail = process.env.NEXT_PUBLIC_OWNER_LOGIN_EMAIL?.trim();

  if (ownerId && ownerEmail && trimmed === ownerId) {
    return ownerEmail;
  }

  return trimmed;
}

export function isOwnerLoginConfigured() {
  return Boolean(
    process.env.NEXT_PUBLIC_OWNER_LOGIN_ID?.trim() &&
      process.env.NEXT_PUBLIC_OWNER_LOGIN_EMAIL?.trim(),
  );
}
