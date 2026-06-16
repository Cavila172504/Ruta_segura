import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/crashlytics_scope.dart';
import 'core/config/firebase_app_options.dart';
import 'core/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppBootstrap.initialize(
      firebaseOptions: FirebaseAppOptions.admin,
      appRole: 'admin',
    );
  } catch (e, stack) {
    await CrashlyticsService.recordError(
      e,
      stack,
      reason: 'main_admin.init',
    );
  }

  AppBootstrap.runGuarded(
    () => runApp(
      const ProviderScope(
        observers: [CrashlyticsProviderObserver()],
        child: CrashlyticsScope(child: AdminApp()),
      ),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaSegura - Panel Administrador',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
