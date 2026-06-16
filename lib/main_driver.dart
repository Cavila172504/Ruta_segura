import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_app_options.dart';
import 'core/screens/login_screen.dart';
import 'core/services/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'features/driver/screens/driver_main_shell.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/parent/screens/parent_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('--- ARRANCANDO APP CHOFER ---');
  
  await Firebase.initializeApp(
    options: FirebaseAppOptions.driver,
  ).timeout(const Duration(seconds: 10));

  // Registrar handler para segundo plano
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializar servicio de notificaciones
  await NotificationService().init();

  runApp(const ProviderScope(child: DriverApp()));
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaSegura - Chofer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const RootAuthWrapper(isDriverApp: true),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RootAuthWrapper extends ConsumerWidget {
  final bool isDriverApp;
  const RootAuthWrapper({super.key, this.isDriverApp = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return LoginScreen(isDriverApp: isDriverApp);
        }

        // Determine user role
        return FutureBuilder<String?>(
          future: ref.read(authRepositoryProvider).getUserRole(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = snapshot.data ?? (isDriverApp ? 'driver' : 'parent');
            if (role == 'driver') {
              return const DriverMainShell();
            } else if (role == 'admin' || role == 'super_admin') {
              return const AdminDashboardScreen();
            } else {
              if (!user.emailVerified) {
                return LoginScreen(isDriverApp: isDriverApp);
              }
              return const ParentDashboardScreen();
            }
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => LoginScreen(isDriverApp: isDriverApp),
    );
  }
}
