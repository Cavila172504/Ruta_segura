# Despliegue y hardening - RutaSegura

Ver android/key.properties.example y .github/workflows/ci.yml

## Android keystore
keytool -genkey -v -keystore android/keystore/rutasegura-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rutasegura

## Migracion padres
cd web_admin && node scripts/migrate-parent-profiles.js --apply
