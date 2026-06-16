# Despliegue y hardening - RutaSegura

## Secretos y API keys

| Archivo | Uso | En git |
|---------|-----|--------|
| `env.json` | Google Maps en Dart (`--dart-define-from-file`) | No |
| `env.example.json` | Plantilla Flutter | Sí |
| `android/secrets.properties` | Google Maps en AndroidManifest | No |
| `ios/Flutter/Secrets.xcconfig` | Google Maps en iOS | No |
| `web_admin/.env.local` | Firebase web + service account | No |
| `lib/firebase_options.dart` | Firebase móvil (FlutterFire) | Sí* |
| `android/app/google-services.json` | Firebase Android | Sí* |

\* Claves de cliente Firebase: restringir en GCP por app ID / SHA-1 / bundle ID.

### Google Maps

1. Crear clave en [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Habilitar: Maps SDK for Android, Maps SDK for iOS, Directions API
3. Restringir por:
   - Android: `com.rutasegura.parent`, `com.rutasegura.driver` (+ SHA-1 del keystore)
   - iOS: bundle IDs por app (`com.rutasegura.parent`, `com.rutasegura.driver`)
   - API: solo las APIs necesarias

### Panel web en Firebase Hosting

Configurar en el entorno de build/hosting:

- `NEXT_PUBLIC_FIREBASE_*` (variables del cliente)
- `FIREBASE_SERVICE_ACCOUNT` (JSON del service account, solo servidor)

## Android keystore

```bash
keytool -genkey -v -keystore android/keystore/rutasegura-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rutasegura
```

Ver `android/key.properties.example`.

## Build release Flutter

Ver [ANDROID_FLAVORS.md](ANDROID_FLAVORS.md).

```bash
cp env.example.json env.json   # con clave real
./scripts/build-android-apk.sh parent release
./scripts/build-android-apk.sh driver release
```

## Migración padres

```bash
cd web_admin && node scripts/migrate-parent-profiles.js --apply
```

## Assets

```bash
python3 scripts/generate_placeholder_assets.py
```

Sustituir por diseño final antes de publicar en tiendas.
