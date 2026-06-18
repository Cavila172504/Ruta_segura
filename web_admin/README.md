# RutaSegura — Web Admin

Panel Next.js para Super Admin, administradores de colegio y monitoreo.

## Diagnóstico rápido

```bash
cd web_admin
npm run check-setup
npm run dev
```

Abre: http://localhost:3000/api/health

- `adminReady: true` → crear colegios, conductores y APIs funcionan.
- `adminReady: false` → solo lectura desde Firestore (super admin ve colegios si hay datos).

## Configuración local (obligatoria para crear/editar)

1. Copia `.env.example` → `.env.local`
2. Firebase Console → **Project settings** → **Service accounts** → **Generate new private key**
3. Guarda el JSON en `web_admin/secrets/rutasegura-a74f7-firebase-adminsdk.json`
4. En `.env.local`:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=secrets/rutasegura-a74f7-firebase-adminsdk.json
```

5. Reinicia `npm run dev`

## Super Admin

Login con ID propietario (si está en `.env.local`) o correo del super usuario.

Script para crear/actualizar super admin en Firestore:

```bash
# Requiere FIREBASE_SERVICE_ACCOUNT o PATH en .env.local
node scripts/create-superuser.js
```

## Producción (Firebase Hosting)

En Firebase Console → App Hosting → Environment / Secrets, define:

- `FIREBASE_SERVICE_ACCOUNT` = JSON completo en una línea **o**
- Asegura que el servicio de Cloud Run tenga permisos Admin (ADC)

Luego:

```bash
firebase deploy --only hosting
```

## Roles

| Rol | Alcance |
|-----|---------|
| super_admin | Todos los colegios, facturación global |
| admin | Un `unitCode` (ej. CAD31) |
| viewer | Solo lectura del colegio |
