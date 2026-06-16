/// Configuracion cargada via `--dart-define-from-file=env.json`.
class AppConfig {
  AppConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String appFlavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'parent',
  );

  static bool get hasGoogleMapsKey => googleMapsApiKey.isNotEmpty;
}