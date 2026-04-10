import 'package:geolocator/geolocator.dart';

class ProximityService {
  /// Distancia mínima de alerta en metros (Ej. 600 metros)
  static const double alertThresholdMeters = 600.0;

  /// Calcula la distancia real en metros entre la furgoneta y la parada de la casa
  static double calculateDistanceBetween(
    double driverLat, 
    double driverLng, 
    double stopLat, 
    double stopLng
  ) {
    return Geolocator.distanceBetween(
      driverLat, 
      driverLng, 
      stopLat, 
      stopLng
    );
  }

  /// Retorna TRUE si el bus ha cruzado el anillo perimetral designado (Ej. 600m max)
  static bool isBusApproaching(
    double driverLat, 
    double driverLng, 
    double stopLat, 
    double stopLng
  ) {
    final distance = calculateDistanceBetween(driverLat, driverLng, stopLat, stopLng);
    return distance <= alertThresholdMeters;
  }
}
