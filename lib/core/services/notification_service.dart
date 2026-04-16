import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      // 1. Configuración de Notificaciones Locales
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notificación local click: ${response.payload}');
        },
      );

      // 2. Configuración de Firebase Cloud Messaging (Push)
      if (!kIsWeb) {
        // Pedir permisos (iOS y Android 13+)
        NotificationSettings settings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('Estado de permisos FCM: ${settings.authorizationStatus}');

        // Escuchar mensajes en primer plano
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Mensaje Push recibido en primer plano: ${message.notification?.title}');
          if (message.notification != null) {
            showLocalNotification(
              id: message.hashCode,
              title: message.notification!.title ?? 'Nueva Alerta',
              body: message.notification!.body ?? '',
            );
          }
        });
      }
    } catch (e) {
      print('NotificationService init error: $e');
    }
  }

  /// Permite a un padre suscribirse a las alertas de un bus específico
  Future<void> subscribeToBus(String unitCode) async {
    await _fcm.subscribeToTopic('bus_$unitCode');
    debugPrint('Suscrito a alertas de la unidad: $unitCode');
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'proximity_channel',
      'Alertas de Proximidad',
      channelDescription: 'Notificaciones cuando el bus está cerca',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
