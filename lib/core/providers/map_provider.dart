import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

// Proveedor del servicio inyectado
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Proveedor de permisos iniciales
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.handleLocationPermission();
});

// Proveedor del Stream en tiempo real de la ubicación
final currentLocationStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getLocationStream();
});

// Estado inicial genérico por defecto (Centro educativo, por ejemplo)
const LatLng defaultInitialLocation = LatLng(4.6533326, -74.083652); // Ejemplo: Bogotá - Centro

// Controladores del mapa (Migración a Notifier para Riverpod 3.x)
class MapControllerNotifier extends Notifier<GoogleMapController?> {
  @override
  GoogleMapController? build() => null;
  
  void setController(GoogleMapController controller) {
    state = controller;
  }
}

final mapControllerProvider = NotifierProvider<MapControllerNotifier, GoogleMapController?>(
  () => MapControllerNotifier()
);
