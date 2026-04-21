import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Servicio para enviar notificaciones push a través del endpoint
/// `/api/notify` del web_admin (Next.js).
///
/// Este servicio es el reemplazo de las Cloud Functions (que requieren Blaze).
/// El web_admin actúa como servidor y usa Firebase Admin SDK para enviar FCM.
///
/// Configuración de la URL:
///   - LOCAL (desarrollo):  http://10.0.2.2:3000  (emulador)
///   - LOCAL (dispositivo físico): http://192.168.X.X:3000 (IP de tu PC)
///   - PRODUCCIÓN: https://tu-dominio.vercel.app (cuando se despliegue en Vercel)
class PushNotificationSender {
  static const String _baseUrl = String.fromEnvironment(
    'NOTIFY_API_URL',
    defaultValue: 'http://10.20.4.44:3000', // IP local de tu PC
  );

  /// Envía una notificación push a TODOS los padres de un bus (via FCM Topic).
  /// El padre debe estar suscrito al topic `bus_{unitCode}` para recibirla.
  static Future<void> notifyTopic({
    required String unitCode,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await _post({
      'topic': 'bus_$unitCode',
      'title': title,
      'body': body,
      'data': data,
    });
  }

  /// Envía una notificación push a un padre específico (via FCM Token).
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
      final uri = Uri.parse('$_baseUrl/api/notify');
      debugPrint('📤 Enviando push a: $uri — payload: $payload');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('✅ Push enviado correctamente: ${response.body}');
      } else {
        debugPrint('⚠️ Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // No bloquear la app si la notificación falla
      debugPrint('⚠️ PushNotificationSender error: $e');
    }
  }
}
