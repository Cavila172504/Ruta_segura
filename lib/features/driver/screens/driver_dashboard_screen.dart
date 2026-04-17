import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_qr_screen.dart';
import '../../parent/screens/parent_dashboard_screen.dart';
import 'driver_route_creator_screen.dart';
import '../../../core/screens/login_screen.dart';
import 'driver_main_shell.dart';
import '../../../core/providers/navigation_provider.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  // Colores Premium para el Conductor (Identidad RutaSegura)
  final Color _primaryDriver = const Color(0xFF0D4D3A); // Esmeralda Profundo
  final Color _accentDriver = const Color(0xFFFFD600);  // Amarillo Bus
  final Color _surfaceDriver = const Color(0xFFF4F7F6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showLocationDialog('GPS Desactivado', 'Por favor, activa el GPS para que el sistema de rastreo funcione correctamente.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showLocationDialog('Permiso Denegado', 'Necesitamos tu ubicación para que los padres puedan ver el progreso del bus.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showLocationDialog('Permiso Bloqueado', 'Has denegado permanentemente el acceso a la ubicación. Por favor, actívalo en los ajustes del sistema.');
      return;
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: _primaryDriver)),
        content: Text(message, style: GoogleFonts.publicSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ENTENDIDO', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: _primaryDriver)),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡BUEN DÍA!';
    if (hour < 18) return '¡BUENAS TARDES!';
    return '¡BUENAS NOCHES!';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Scaffold(
      backgroundColor: _surfaceDriver,
      body: Stack(
        children: [
          // Header Background (Degradado Esmeralda)
          Positioned(
            top: 0, left: 0, right: 0,
            height: 260,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryDriver, const Color(0xFF167159)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
            ),
          ),

          // Contenido Principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera: Perfil y Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _initialAvatar(profileAsync),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: GoogleFonts.publicSans(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              profileAsync.when(
                                data: (p) => Text(
                                  (p?['name'] as String? ?? 'Conductor').split(' ').first,
                                  style: GoogleFonts.publicSans(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                loading: () => const SizedBox(width: 50, height: 20),
                                error: (_, __) => const Text('Hola!', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _topActionButton(Icons.qr_code_scanner, () {
                             final unitCode = profileAsync.value?['unitCode'] ?? 'CAD31';
                             Navigator.push(context, MaterialPageRoute(builder: (_) => DriverQrScreen(unitCode: unitCode)));
                          }),
                          const SizedBox(width: 8),
                          _topActionButton(Icons.logout_rounded, () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tarjeta de Estado Rápido
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _quickInfo(Icons.today, 'FECHA', dateStr),
                        Container(width: 1, height: 35, color: Colors.grey.shade100),
                        profileAsync.when(
                          data: (p) => _quickInfo(Icons.tag, 'UNIDAD', p?['unitCode'] ?? 'CAD31'),
                          loading: () => _quickInfo(Icons.tag, 'UNIDAD', '...'),
                          error: (_, __) => _quickInfo(Icons.tag, 'UNIDAD', '--'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Lista de Operaciones
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECORRIDO DEL DÍA',
                          style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta de Ruta Actual
                        profileAsync.when(
                          data: (profile) {
                            final unitCode = profile?['unitCode'] as String? ?? 'CAD31';
                            return Consumer(
                              builder: (context, ref, _) {
                                final routeAsync = ref.watch(activeRouteProvider(unitCode));
                                final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
                                return routeAsync.when(
                                  loading: () => _skeleton(),
                                  error: (_, __) => _routeCard('Ruta CAD31', 0, 0, 'CAD31'),
                                  data: (route) => _routeCard(
                                    route?['name'] ?? 'Ruta Principal',
                                    studentsAsync.value?.length ?? 0,
                                    route?['stopCount'] ?? 0,
                                    unitCode
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => _skeleton(),
                          error: (_, __) => _skeleton(),
                        ),

                        const SizedBox(height: 20),
                        
                        // Banner Próximo Paso
                        _nextActivityBanner(),

                        const SizedBox(height: 16),

                        // NUEVA ACCIÓN: MODO ARQUITECTO
                        _architectModeCard(context),
                        
                        const SizedBox(height: 120), // Espacio para el botón flotante
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón Flotante de INICIO
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: profileAsync.maybeWhen(
              data: (profile) => _startBtn(context, ref, profile),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Componentes Específicos ────────────────────────────────────

  Widget _initialAvatar(AsyncValue<Map<String, dynamic>?> profile) {
    return profile.when(
      data: (p) => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _accentDriver),
        child: Center(
          child: Text(
            (p?['name'] as String? ?? 'C')[0].toUpperCase(),
            style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, fontSize: 18, color: _primaryDriver),
          ),
        ),
      ),
      loading: () => CircleAvatar(backgroundColor: _accentDriver, radius: 22),
      error: (_, __) => const CircleAvatar(child: Icon(Icons.person)),
    );
  }

  Widget _topActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _quickInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.publicSans(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _primaryDriver),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.w900, color: _primaryDriver)),
          ],
        ),
      ],
    );
  }

  Widget _routeCard(String name, int pax, int stops, String unit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: _primaryDriver.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _primaryDriver.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                        child: Text('ESTADO: ACTIVA', style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900, color: _primaryDriver)),
                      ),
                      const SizedBox(height: 8),
                      Text(name, style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w900, color: _primaryDriver)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _accentDriver.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.route_rounded, color: _primaryDriver),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: _primaryDriver.withOpacity(0.03),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(Icons.people_rounded, '$pax Pax'),
                _miniStat(Icons.place_rounded, '$stops Paradas'),
                _miniStat(Icons.timer_rounded, '30 min'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String val) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _primaryDriver.withOpacity(0.5)),
        const SizedBox(width: 5),
        Text(val, style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w800, color: _primaryDriver)),
      ],
    );
  }

  Widget _nextActivityBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryDriver,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _accentDriver, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.rocket_launch_rounded, color: _primaryDriver, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIGUIENTE ACCIÓN', style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900, color: _accentDriver, letterSpacing: 1)),
                Text('Iniciar transmisión GPS', style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _architectModeCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverRouteCreatorScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _primaryDriver.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _primaryDriver.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.explore_rounded, color: _primaryDriver),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONFIGURACIÓN AVANZADA', style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1)),
                  Text('Modo Arquitecto de Rutas', style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryDriver)),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: _primaryDriver, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _startBtn(BuildContext context, WidgetRef ref, dynamic profile) {
    return InkWell(
      onTap: () async {
        final driverId = profile?['uid'] ?? 'UNKNOWN';
        final unitCode = profile?['unitCode'] ?? 'CAD31';
        
        // 1. Cambiar estado en Firebase
        await ref.read(trackingRepositoryProvider).updateRouteStatus(unitCode, driverId, 'on_route');

        // 2. Notificar a todos los padres de la ruta que el bus ha iniciado
        try {
          final studentsSnapshot = await FirebaseFirestore.instance
              .collection('companies').doc(unitCode).collection('students').get();
          
          final batch = FirebaseFirestore.instance.batch();
          final now = Timestamp.now();

          for (var doc in studentsSnapshot.docs) {
            final parentUid = doc.data()['parentUid'] as String?;
            if (parentUid != null) {
              final notificationRef = FirebaseFirestore.instance
                  .collection('users').doc('parents').collection('members').doc(parentUid)
                  .collection('notifications').doc();
              
              batch.set(notificationRef, {
                'title': '🚌 Recorrido Iniciado',
                'message': 'El transporte ha iniciado su recorrido hacia el colegio. ¡Ten un excelente día!',
                'timestamp': now,
                'type': 'trip_started',
                'isRead': false,
              });
            }
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Error enviando notificaciones de inicio: $e');
        }

        if (context.mounted) {
           ref.read(driverNavigationProvider.notifier).setIndex(1); // Cambiar a la pestaña de MAPA
        }
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: _accentDriver,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _accentDriver.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_filled_rounded, color: _primaryDriver, size: 28),
              const SizedBox(width: 12),
              Text('INICIAR RECORRIDO', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w900, color: _primaryDriver, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton() => Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)));
}
