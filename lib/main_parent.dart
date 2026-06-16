import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/crashlytics_scope.dart';
import 'core/config/firebase_app_options.dart';
import 'core/screens/login_screen.dart';
import 'core/services/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'features/driver/screens/driver_main_shell.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/parent/screens/parent_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppBootstrap.initialize(
      firebaseOptions: FirebaseAppOptions.parent,
      appRole: 'parent',
    ).timeout(const Duration(seconds: 10));

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService().init().timeout(const Duration(seconds: 5));
  } catch (e, stack) {
    await CrashlyticsService.recordError(
      e,
      stack,
      reason: 'main_parent.init',
    );
  }

  AppBootstrap.runGuarded(
    () => runApp(
      const ProviderScope(
        observers: [CrashlyticsProviderObserver()],
        child: CrashlyticsScope(child: ParentApp()),
      ),
    ),
  );
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaSegura - Padre',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const RootAuthWrapper(),
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

        return FutureBuilder<String?>(
          future: ref.read(authRepositoryProvider).getUserRole(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = snapshot.data ?? 'parent';
            if (role == 'driver') {
              return const DriverMainShell();
            } else if (role == 'admin' || role == 'super_admin') {
              return const AdminDashboardScreen();
            } else {
              if (!user.emailVerified) {
                return const LoginScreen(isDriverApp: false);
              }
              return const ParentDashboardScreen();
            }
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => LoginScreen(isDriverApp: isDriverApp),
    );
  }
}
