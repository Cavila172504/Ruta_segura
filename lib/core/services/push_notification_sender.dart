import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Envía notificaciones push vía `/api/notify` del panel (Firebase Admin + FCM).
///
/// Build producción:
///   flutter build apk --dart-define=NOTIFY_API_URL=https://TU-DOMINIO.web.app
class PushNotificationSender {
  static const String _baseUrl = String.fromEnvironment(
    'NOTIFY_API_URL',
    defaultValue: 'https://rutasegura-a74f7.web.app',
  );

  static Future<void> notifyTopic({
    required String unitCode,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await _post({
      'topic': 'bus_$unitCode',
      'unitCode': unitCode,
      'title': title,
      'body': body,
      'data': data,
    });
  }

  static Future<void> notifyToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await _post({
      'token': fcmToken,
      'title': title,
      'body': body,
      'data': data,
    });
  }

  static Future<void> _post(Map<String, dynamic> payload) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ PushNotificationSender: usuario no autenticado');
        return;
      }

      final idToken = await user.getIdToken();
      final uri = Uri.parse('$_baseUrl/api/notify');
      debugPrint('📤 Enviando push a: $uri');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('✅ Push enviado: ${response.body}');
      } else {
        debugPrint('⚠️ Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ PushNotificationSender error: $e');
    }
  }
}
