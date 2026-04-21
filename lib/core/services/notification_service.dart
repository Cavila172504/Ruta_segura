import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// BACKGROUND HANDLER — debe ser una función de nivel superior (top-level).
/// Se ejecuta en un Isolate separado cuando la app está CERRADA o en segundo
/// plano. Firebase lo llama automáticamente al recibir un mensaje push.
/// ─────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Mostramos la notificación local aunque la app esté cerrada.
  final plugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'ruta_segura_alerts_high_v2',
    'Alertas Urgentes RutaSegura',
    description: 'Notificaciones importantes de la ruta escolar.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit),
  );

  final title = message.notification?.title ?? message.data['title'] ?? 'RutaSegura';
  final body  = message.notification?.body  ?? message.data['body']  ?? '';

  await plugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'ruta_segura_alerts_high_v2',
        'Alertas Urgentes RutaSegura',
        channelDescription: 'Notificaciones importantes de la ruta escolar.',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
      ),
    ),
  );
}

/// ─────────────────────────────────────────────────────────────────────────
/// NOTIFICATION SERVICE — singleton para uso dentro de la app
/// ─────────────────────────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _channelId   = 'ruta_segura_alerts_high_v2'; // Nuevo ID para forzar configuración
  static const String _channelName = 'Alertas Urgentes RutaSegura';
  static const String _channelDesc = 'Notificaciones importantes de la ruta escolar.';

  Future<void> init() async {
    try {
      // 1. Crear canal Android de alta prioridad
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 2. Inicializar plugin local
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      await _localNotifications.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: (NotificationResponse r) {
          debugPrint('Notificación local click: ${r.payload}');
        },
      );

      // 3. Permisos FCM
      if (!kIsWeb) {
        await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          criticalAlert: true,
        );

        // Configurar para que las notificaciones lleguen como
        // "high-priority" cuando la app está en segundo plano
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Mensajes cuando la app está abierta (foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Push en primer plano: ${message.notification?.title}');
          if (message.notification != null) {
            showLocalNotification(
              id: message.hashCode,
              title: message.notification!.title ?? 'Nueva Alerta',
              body: message.notification!.body ?? '',
            );
          }
        });

        // Token + guardado en Firestore para que Cloud Functions lo use
        final token = await _fcm.getToken();
        debugPrint('FCM Token: $token');
        if (token != null) {
          await _saveFcmToken(token);
        }

        // Actualizar token si cambia (token refresh)
        _fcm.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM Token renovado: $newToken');
          await _saveFcmToken(newToken);
        });
      }
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  /// Suscribir al padre a las alertas push de una unidad específica.
  Future<void> subscribeToBus(String unitCode) async {
    await _fcm.subscribeToTopic('bus_$unitCode');
    debugPrint('Suscrito al topic: bus_$unitCode');
  }

  /// Mostrar notificación local. Funciona con pantalla apagada gracias
  /// a [fullScreenIntent] y al canal de alta importancia.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      ticker: 'RutaSegura',
      visibility: NotificationVisibility.public, // Visible en pantalla de bloqueo
      category: AndroidNotificationCategory.alarm, // Prioridad máxima de sistema
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }
  /// Guarda el token FCM en Firestore bajo el perfil del padre autenticado.
  /// La Cloud Function `onNewParentNotification` lo usa para enviar push
  /// al dispositivo correcto aunque la app esté cerrada.
  Future<void> _saveFcmToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc('parents')
          .collection('members')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      debugPrint('✅ FCM Token guardado en Firestore para uid: $uid');
    } catch (e) {
      debugPrint('⚠️ Error guardando FCM Token: $e');
    }
  }
}
