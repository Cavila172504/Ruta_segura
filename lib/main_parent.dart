import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/screens/login_screen.dart';
import 'core/services/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'features/driver/screens/driver_main_shell.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/parent/screens/parent_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('--- ARRANCANDO APLICACIÓN ---');

  try {
    print('Iniciando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    print('Firebase listo.');

    // Inicializar notificaciones locales
    print('Iniciando NotificationService...');
    await NotificationService().init().timeout(const Duration(seconds: 5));
    print('NotificationService listo.');
  } catch (e) {
    print('Error o Timeout durante la inicialización: $e');
  }

  runApp(const ProviderScope(child: ParentApp()));
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
  const RootAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen(isDriverApp: false);
        }
        
        // El usuario está logueado, determinar su dashboard
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
              // Validar verificación para padres
              if (!user.emailVerified) {
                return const LoginScreen(isDriverApp: false);
              }
              return const ParentDashboardScreen();
            }
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const LoginScreen(isDriverApp: false),
    );
  }
}
