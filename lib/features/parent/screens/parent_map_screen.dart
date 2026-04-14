import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_proximity_alert_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/map_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/screens/login_screen.dart';

import '../../../core/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';

class ParentMapScreen extends ConsumerStatefulWidget {
  const ParentMapScreen({super.key});

  @override
  ConsumerState<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends ConsumerState<ParentMapScreen> {
  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);
  
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _houseIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    try {
      _busIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/autobus-escolar.png',
      );
      _houseIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/casa.png',
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error cargando iconos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Mapa Interactivo Real Background
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, _) {
                // Lógica de Estado de Ruta (Notificar inicio)
                ref.listen(busStatusProvider, (previous, next) {
                  if (previous?.value == 'idle' && next.value == 'on_route') {
                    NotificationService().showLocalNotification(
                      id: 0,
                      title: '🚩 ¡Ruta Iniciada!',
                      body: 'El bus ha comenzado su recorrido habitual.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🚀 ¡La ruta escolar ha iniciado!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });

                // Lógica de Proximidad para todos los hijos
                ref.listen(liveBusLocationProvider, (previous, next) {
                  final busLoc = next.value;
                  final students = ref.read(parentStudentsProvider).value ?? [];
                  
                  if (busLoc != null) {
                    for (var student in students) {
                      final sLat = student['stopLat'] as double?;
                      final sLng = student['stopLng'] as double?;
                      
                      if (sLat != null && sLng != null) {
                        final distance = Geolocator.distanceBetween(
                          busLoc.latitude, busLoc.longitude,
                          sLat, sLng,
                        );

                        if (distance < 600) {
                          final etaMin = (distance / 300).ceil();
                          NotificationService().showLocalNotification(
                            id: student.hashCode,
                            title: '¡El bus está cerca de ${student['studentName']}!',
                            body: 'Distancia: ${distance.toInt()}m • Tiempo estimado: $etaMin min.',
                          );
                        }
                      }
                    }
                  }
                });

                final locationAsync = ref.watch(currentLocationStreamProvider);
                final polylines = ref.watch(activePolylinesProvider);
                final liveBusLocation = ref.watch(liveBusLocationProvider).value;
                final studentsAsync = ref.watch(parentStudentsProvider);

                LatLng initialPos = defaultInitialLocation;
                if (liveBusLocation != null) initialPos = liveBusLocation;

                final students = studentsAsync.value ?? [];

                return GoogleMap(
                  initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  polylines: polylines,
                  markers: {
                    // Marcadores de mis hijos
                    for (var student in students)
                      if (student['stopLat'] != null && student['stopLng'] != null)
                        Marker(
                          markerId: MarkerId('student_${student['id'] ?? student['studentName']}'),
                          position: LatLng(student['stopLat'] as double, student['stopLng'] as double),
                          infoWindow: InfoWindow(title: 'Parada: ${student['studentName']}'),
                          icon: _houseIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                          anchor: const Offset(0.5, 0.5),
                        ),
                    
                    // Marcador del Bus
                    if (liveBusLocation != null)
                      Marker(
                        markerId: const MarkerId('bus'),
                        position: liveBusLocation,
                        infoWindow: const InfoWindow(title: 'Ruta Escolar en tiempo real'),
                        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                        anchor: const Offset(0.5, 0.5),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ParentProximityAlertScreen(),
                          );
                        },
                      ),
                  },
                  onMapCreated: (controller) {
                    try {
                      ref.read(mapControllerProvider.notifier).setController(controller);
                    } catch (e) {}
                  },
                );
              },
            ),
          ),

          // Top App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRect(
              child: Container(
                color: Colors.white.withOpacity(0.85),
                padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: _primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'BusGuardian',
                          style: GoogleFonts.publicSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                            letterSpacing: -0.5,
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.logout, color: Colors.grey.shade600),
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),



          // Map Controls
          Positioned(
            right: 24,
            top: 120,
            child: Column(
              children: [
                _mapControlButton(Icons.my_location),
                const SizedBox(height: 12),
                _mapControlButton(Icons.layers),
              ],
            ),
          ),

          // Bus Status Toggle Button
          Positioned(
            left: 24,
            bottom: 120,
            child: GestureDetector(
              onTap: () => _showBusDetails(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ESTADO DEL BUS',
                      style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: _primaryContainer.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -8))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context, icon: Icons.home, label: 'Inicio', isActive: false, target: const ParentDashboardScreen()),
                    // BOTÓN DE PRUEBA (Temporal)
                    GestureDetector(
                      onLongPress: () async {
                        final authRepo = ref.read(authRepositoryProvider);
                        final uid = await authRepo.getCurrentUserId();
                        // Intentamos obtener perfil o usamos unidad por defecto
                        final profile = ref.read(userProfileProvider).value;
                        final unitCode = profile?['activeUnitCode'] as String? ?? 'UNIDAD-GENERICA';
                        
                        // Obtenemos el primer estudiante para la prueba
                        final students = ref.read(parentStudentsProvider).value ?? [];
                        if (students.isEmpty) return;
                        
                        final student = students.first;
                        final sLat = student['stopLat'] as double;
                        final sLng = student['stopLng'] as double;
                        
                        // Mover bus a exactamente 500m del objetivo
                        final testLat = sLat + 0.0035; 
                        final testLng = sLng + 0.0035;
                        
                        await ref.read(trackingRepositoryProvider).updateDriverLocation(
                          unitCode, 'TEST_DRIVER_ID', 'Chofer de Prueba', testLat, testLng
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PRUEBA ACTIVADA: Bus enviado a rango de 600m. ¡Bloquea tu pantalla ahora!'),
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      },
                      child: _navItem(context, icon: Icons.map, label: 'Mapa', isActive: true, target: const ParentMapScreen()),
                    ),
                    _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: false, target: const ParentNotificationsScreen()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Icon(icon, color: _primary),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget target}) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFdbeaFE) : Colors.transparent, // blue-100 fallback
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _primaryContainer : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.publicSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isActive ? _primaryContainer : Colors.grey.shade400,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showBusDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, _) {
                  final busLoc = ref.watch(liveBusLocationProvider).value;
                  final students = ref.watch(parentStudentsProvider).value ?? [];
                  String arrivalText = 'Calculando...';
                  
                  if (busLoc != null && students.isNotEmpty) {
                    final firstStudent = students.first;
                    final sLat = firstStudent['stopLat'] as double?;
                    final sLng = firstStudent['stopLng'] as double?;

                    if (sLat != null && sLng != null) {
                      final dist = Geolocator.distanceBetween(
                        busLoc.latitude, busLoc.longitude,
                        sLat, sLng,
                      );
                      final mins = (dist / 300).ceil();
                      arrivalText = dist < 50 ? 'En la puerta' : 'Llega en $mins min';
                    }
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTADO DEL BUS',
                            style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: const Color(0xFF556068)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            arrivalText,
                            style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w900, color: _primary, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFd9e4ee), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Text('PLACA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('ABC-1234', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              // Detalles Adicionales
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFf3f4f5), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blueGrey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ruta en curso. El conductor sigue la trayectoria planificada para garantizar la seguridad.',
                        style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
