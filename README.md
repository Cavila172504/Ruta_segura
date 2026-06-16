# RutaSegura

Sistema de transporte escolar: app Flutter (padres, conductores, admin móvil) y panel web Next.js.

## Apps Flutter

| Target | Entry point |
|--------|-------------|
| Padres | `lib/main_parent.dart` |
| Conductores | `lib/main_driver.dart` |
| Admin móvil | `lib/main_admin.dart` |

## Configuración inicial

### 1. Assets

Los iconos y mockups están en `assets/images/` y `web_admin/public/images/`. Para regenerar placeholders:

```bash
pip install pillow
python3 scripts/generate_placeholder_assets.py
```

Reemplaza `logo.png` y los mockups por tus diseños finales cuando los tengas.

### 2. Claves de Google Maps (Flutter)

```bash
cp env.example.json env.json
# Edita env.json con tu GOOGLE_MAPS_API_KEY

cp android/secrets.properties.example android/secrets.properties
# Misma clave para Android nativo

cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
# Misma clave para iOS nativo
```

Ejecutar con claves:

```bash
flutter run --target lib/main_parent.dart --dart-define-from-file=env.json
```

En VS Code/Cursor usa las configuraciones de `.vscode/launch.json`.

### 3. Panel web (Next.js)

```bash
cd web_admin
cp .env.example .env.local
# Completa NEXT_PUBLIC_FIREBASE_* y FIREBASE_SERVICE_ACCOUNT
npm install
npm run dev
```

### 4. Firebase móvil

`lib/firebase_options.dart` y `android/app/google-services.json` son generados por FlutterFire. Restringe las claves en Google Cloud Console por package/bundle ID.

## Despliegue y seguridad

Ver [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) para builds release, reglas Firestore y checklist de producción.
