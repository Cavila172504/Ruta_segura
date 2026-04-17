import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/proximity_service.dart';
import 'app_providers.dart';
import 'notification_list_provider.dart';
import 'route_provider.dart';

/// Provider que monitorea las cercanías de los buses en tiempo real para el padre.
final proximityMonitoringProvider = Provider<void>((ref) {
  final studentsAsync = ref.watch(parentStudentsProvider);
  
  studentsAsync.whenData((students) {
    for (final student in students) {
      final unitCode = student['unitCode'] as String?;
      final stopLat = student['stopLat'] as double?;
      final stopLng = student['stopLng'] as double?;

      if (unitCode == null || stopLat == null || stopLng == null) continue;

      // Escuchamos a CUALQUIER conductor activo de la unidad del estudiante
      // Usamos un StreamProvider simple para la unidad
      ref.listen(liveBusLocationProvider, (previous, next) {
        final busPos = next.value;
        if (busPos == null) return;

        final distanceMeters = Geolocator.distanceBetween(
          busPos.latitude, busPos.longitude, 
          stopLat, stopLng
        );

        final prevPos = previous?.value;
        final double prevDist = prevPos != null 
            ? Geolocator.distanceBetween(prevPos.latitude, prevPos.longitude, stopLat, stopLng)
            : 999999.0;

        // 1. Lógica de "Bus a 600m"
        if (distanceMeters <= ProximityService.alertThresholdMeters && prevDist > ProximityService.alertThresholdMeters) {
          final etaMin = (distanceMeters / 300).ceil();
          final title = 'Bus cerca de ${student['studentName']}';
          final body = 'Está a ${distanceMeters.toInt()}m. Llega en aprox. $etaMin min.';

          final user = ref.read(authStateProvider).value;
          if (user != null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc('parents')
                .collection('members')
                .doc(user.uid)
                .collection('notifications')
                .add({
              'title': title,
              'message': body,
              'timestamp': Timestamp.now(),
              'type': 'proximity',
              'isRead': false,
            });
          }
          NotificationService().showLocalNotification(id: 102, title: title, body: body);
        }
      });
    }
  });
});
