import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';
import '../services/proximity_service.dart';
import 'app_providers.dart';
import 'notification_list_provider.dart';

/// Provider que monitorea las cercanías de los buses en tiempo real para el padre.
final proximityMonitoringProvider = Provider<void>((ref) {
  final studentsAsync = ref.watch(parentStudentsProvider);
  final trackingRepo = ref.read(trackingRepositoryProvider);

  studentsAsync.whenData((students) {
    for (final student in students) {
      final unitCode = student['unitCode'] as String?;
      final stopLat = student['stopLat'] as double?;
      final stopLng = student['stopLng'] as double?;

      if (unitCode != null && stopLat != null && stopLng != null) {
        ref.listen(StreamProvider((ref) => trackingRepo.listenToDriverLocation(unitCode)), (previous, next) {
          final doc = next.value;
          if (doc != null && doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            final driverLat = data?['lat'] as double?;
            final driverLng = data?['lng'] as double?;
            final status = data?['status'] as String?;

            if (driverLat != null && driverLng != null) {
              final distanceMeters = Geolocator.distanceBetween(driverLat, driverLng, stopLat, stopLng);

              // 1. Lógica de "Bus iniciando recorrido"
              if (previous?.value?.get('status') != 'active' && status == 'active') {
                final notification = AppNotification(
                  id: DateTime.now().toString(),
                  title: 'Bus iniciando recorrido',
                  subtitle: 'La unidad $unitCode ha comenzado su ruta hacia el colegio.',
                  timestamp: DateTime.now(),
                  type: NotificationType.busStart,
                );
                ref.read(notificationListProvider.notifier).addNotification(notification);
                NotificationService().showLocalNotification(id: 101, title: notification.title, body: notification.subtitle);
              }

              // 2. Lógica de "Bus a 600m"
              if (distanceMeters <= ProximityService.alertThresholdMeters &&
                  (previous?.value == null || 
                   Geolocator.distanceBetween(previous!.value!.get('lat'), previous.value!.get('lng'), stopLat, stopLng) > ProximityService.alertThresholdMeters)) {
                
                final etaMin = (distanceMeters / 300).ceil();
                final notification = AppNotification(
                  id: DateTime.now().toString(),
                  title: 'Bus a 600m de tu parada',
                  subtitle: 'Prepárate, el bus está llegando en aprox. $etaMin min (${(distanceMeters/1000).toStringAsFixed(1)} km).',
                  timestamp: DateTime.now(),
                  type: NotificationType.proximity,
                );
                ref.read(notificationListProvider.notifier).addNotification(notification);
                NotificationService().showLocalNotification(id: 102, title: notification.title, body: notification.subtitle);
              }
            }
          }
        });
      }
    }
  });
});
