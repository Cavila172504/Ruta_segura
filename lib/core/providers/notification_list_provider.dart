import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_providers.dart';

enum NotificationType { alert, busStart, proximity, boarded, arrival, support, trip_started }

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

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'alert';
    NotificationType t;
    switch (typeStr) {
      case 'trip_started':
      case 'busStart':
        t = NotificationType.busStart;
        break;
      case 'boarded':
        t = NotificationType.boarded;
        break;
      case 'arrival':
        t = NotificationType.arrival;
        break;
      case 'support':
        t = NotificationType.support;
        break;
      case 'proximity':
        t = NotificationType.proximity;
        break;
      default:
        t = NotificationType.alert;
    }

    final ts = data['timestamp'] as Timestamp?;
    final date = ts?.toDate() ?? DateTime.now();

    return AppNotification(
      id: id,
      title: data['title'] ?? 'Notificación',
      subtitle: data['message'] ?? '',
      timestamp: date,
      type: t,
      isRead: data['isRead'] ?? false,
    );
  }
}

final notificationListProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => AppNotification.fromMap(doc.id, doc.data())).toList());
});
