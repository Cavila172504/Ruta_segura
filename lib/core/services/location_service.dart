import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Solicita permisos de ubicación al usuario
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Los servicios de ubicación están deshabilitados.
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // El usuario volvió a denegar
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false; // Permisos denegados permanentemente
    }
    return true;
  }

  /// Obtiene la posición actual por única vez
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Retorna un flujo (Stream) para rastreo en vivo de la posición
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Notificar solo si se movió 5 metros
      ),
    );
  }
}
