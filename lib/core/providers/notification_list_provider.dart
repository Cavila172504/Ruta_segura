import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType { alert, busStart, proximity, boarded, arrival }

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationListNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => _getInitialDemos();

  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          AppNotification(
            id: n.id,
            title: n.title,
            subtitle: n.subtitle,
            timestamp: n.timestamp,
            type: n.type,
            isRead: true,
          )
        else
          n,
    ];
  }

  static List<AppNotification> _getInitialDemos() {
    return [
      AppNotification(
        id: '1',
        title: 'ALERTA: novedad en la vía',
        subtitle: 'Se reporta tráfico pesado en la Av. Principal. El tiempo de llegada podría verse afectado.',
        timestamp: DateTime.now(),
        type: NotificationType.alert,
      ),
      AppNotification(
        id: '2',
        title: 'Bus iniciando recorrido',
        subtitle: 'La unidad 24 ha comenzado su ruta hacia el colegio.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.busStart,
      ),
    ];
  }
}

final notificationListProvider = NotifierProvider<NotificationListNotifier, List<AppNotification>>(() {
  return NotificationListNotifier();
});
