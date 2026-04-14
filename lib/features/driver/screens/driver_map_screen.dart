import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'driver_dashboard_screen.dart';
import 'driver_stop_detail_screen.dart';
import 'driver_attendance_screen.dart';
import 'driver_profile_screen.dart';
import '../../../core/screens/login_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/map_provider.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  bool _isDetailVisible = false;
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
    final profileAsync = ref.watch(userProfileProvider);
    final permissionAsync = ref.watch(locationPermissionProvider);
    
    // Si el perfil está cargando, mostrar pantalla de carga
    if (profileAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unitCode = profileAsync.value?['unitCode'] as String? ?? 'UNIDAD-GENERICA';
    final driverId = profileAsync.value?['uid'] as String? ?? 'UID-GENERICO';
    final driverName = profileAsync.value?['name'] as String? ?? 'CONDUCTOR DESCONOCIDO';
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Interactive Map Area
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, _) {
                // Sincronizar ubicación con Firestore
                ref.listen(currentLocationStreamProvider, (previous, next) async {
                  final position = next.value;
                  if (position != null) {
                    ref.read(trackingRepositoryProvider).updateDriverLocation(
                      unitCode, 
                      driverId,
                      driverName,
                      position.latitude, 
                      position.longitude,
                    );
                    
                    // Centrar mapa la primera vez que recibimos ubicación
                    if (previous?.hasValue != true) {
                      final controller = ref.read(mapControllerProvider);
                      controller?.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
                    }
                  }
                });

                final locationAsync = ref.watch(currentLocationStreamProvider);
                final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
                
                LatLng initialPos = defaultInitialLocation;
                if (locationAsync.hasValue) {
                  initialPos = LatLng(locationAsync.value!.latitude, locationAsync.value!.longitude);
                }

                // Generar Marcadores
                final Set<Marker> markers = {};
                final Set<Polyline> polylines = {};

                // 1. Marcador del Bus (Conductor) con Imagen Personalizada
                if (locationAsync.hasValue) {
                  markers.add(
                    Marker(
                      markerId: const MarkerId('driver_bus'),
                      position: LatLng(locationAsync.value!.latitude, locationAsync.value!.longitude),
                      icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(title: 'MI BUS'),
                      anchor: const Offset(0.5, 0.5),
                    ),
                  );
                }

                // 2. Marcadores de Estudiantes (Casitas)
                final studentsRaw = studentsAsync.value ?? [];
                
                // Filtramos solo los que no han sido recogidos
                final activeStudents = studentsRaw.where((s) => s['status'] != 'picked_up' && s['status'] != 'absent').toList();

                final List<Map<String, dynamic>> students = activeStudents.isNotEmpty 
                  ? activeStudents 
                  : (studentsRaw.isEmpty ? [
                      {
                        'id': 'test_student',
                        'studentName': 'ESTUDIANTE DE PRUEBA',
                        'stopLat': initialPos.latitude + 0.005,
                        'stopLng': initialPos.longitude + 0.005,
                      }
                    ] : []);

                for (int i = 0; i < students.length; i++) {
                  final student = students[i];
                  final lat = student['stopLat'] as double?;
                  final lng = student['stopLng'] as double?;
                  if (lat != null && lng != null) {
                    markers.add(
                      Marker(
                        markerId: MarkerId('student_${student['id']}'),
                        position: LatLng(lat, lng),
                        icon: _houseIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                          i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRose
                        ),
                        infoWindow: InfoWindow(title: 'Parada: ${student['studentName']}'),
                      ),
                    );
                  }
                }

                // 3. Crear Polyline Secuencial (Ruta estilo Uber)
                if (locationAsync.hasValue && students.isNotEmpty) {
                  List<LatLng> routePoints = [
                    LatLng(locationAsync.value!.latitude, locationAsync.value!.longitude)
                  ];
                  
                  // Agregamos todos los estudiantes restantes a la trayectoria
                  for (var s in students) {
                    final sLat = s['stopLat'] as double?;
                    final sLng = s['stopLng'] as double?;
                    if (sLat != null && sLng != null) {
                      routePoints.add(LatLng(sLat, sLng));
                    }
                  }

                  polylines.add(
                    Polyline(
                      polylineId: const PolylineId('full_route'),
                      color: const Color(0xFF044837),
                      width: 6,
                      points: routePoints,
                      geodesic: true,
                      jointType: JointType.round,
                    ),
                  );
                }

                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: initialPos, zoom: 15),
                      myLocationEnabled: false, 
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      markers: markers,
                      polylines: polylines,
                      onMapCreated: (controller) {
                        ref.read(mapControllerProvider.notifier).setController(controller);
                      },
                    ),
                    if (locationAsync.isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (!locationAsync.hasValue)
                      Positioned(
                        top: 140, left: 24, right: 24,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: Text('⚠️ Esperando señal GPS o permisos...', textAlign: TextAlign.center, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ),
                    
                    // Botón de Inicio de Ruta (Prominente)
                    Positioned(
                      top: 145,
                      left: 24,
                      right: 24,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: ref.watch(trackingRepositoryProvider).listenToDriverLocation(unitCode, driverId),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          final bool isOnRoute = data?['status'] == 'on_route';

                          return ElevatedButton(
                            onPressed: () async {
                              final newStatus = isOnRoute ? 'idle' : 'on_route';
                              await ref.read(trackingRepositoryProvider).updateRouteStatus(unitCode, driverId, newStatus);
                              
                              if (context.mounted && !isOnRoute) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ Ruta Iniciada. Los padres han sido notificados.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOnRoute ? Colors.red : const Color(0xFF044837),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isOnRoute ? Icons.stop_circle : Icons.play_circle_fill),
                                const SizedBox(width: 8),
                                Text(
                                  isOnRoute ? 'FINALIZAR RECORRIDO' : 'INICIAR RECORRIDO DEL DÍA',
                                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ),

                    // Badge de Unidad Activa
                    Positioned(
                      top: 110,
                      left: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF044837),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_bus, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'UNIDAD: $unitCode',
                              style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Top Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: const Color(0xFF044837),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 24,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            profileAsync.value?['name'] != null 
                              ? profileAsync.value!['name'].toString()[0].toUpperCase() 
                              : 'C',
                            style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF044837)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'RUTASEGURA',
                        style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.primaryContainer),
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
              ),
            ),
          ),

          // Floating Emergency Button
          Positioned(
            right: 24,
            bottom: _isDetailVisible ? 380 : 100,
            child: FloatingActionButton(
              backgroundColor: AppColors.error,
              onPressed: () {},
              child: const Icon(Icons.warning, color: Colors.white),
            ),
          ),

          // Toggle Bottom Sheet Button
          Positioned(
            left: 24,
            bottom: _isDetailVisible ? 380 : 100,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF044837),
              onPressed: () => setState(() => _isDetailVisible = !_isDetailVisible),
              child: Icon(_isDetailVisible ? Icons.expand_more : Icons.route, color: Colors.white),
            ),
          ),

          // Collapsible Bottom Sheet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isDetailVisible ? 64 : -400,
            left: 0, right: 0,
            child: Consumer(
              builder: (context, ref, _) {
                final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
                final driverLocation = ref.watch(currentLocationStreamProvider).value;

                final students = studentsAsync.value ?? [];
                final activeStudents = students.where((s) => s['status'] != 'absent').toList();
                final nextStudent = activeStudents.isNotEmpty ? activeStudents.first : null;

                final studentName = nextStudent?['studentName'] as String? ?? 'Sin paradas';
                final stopLat = nextStudent?['stopLat'] as double?;
                final stopLng = nextStudent?['stopLng'] as double?;

                double? distanceKm;
                int? etaMin;
                if (driverLocation != null && stopLat != null && stopLng != null) {
                  final distM = Geolocator.distanceBetween(driverLocation.latitude, driverLocation.longitude, stopLat, stopLng);
                  distanceKm = distM / 1000;
                  etaMin = (distM / 300).ceil();
                }

                return Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, -10))]
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SIGUIENTE PARADA', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Text(studentName, style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (distanceKm != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${distanceKm.toStringAsFixed(1)} KM', style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                                    Text('$etaMin MIN', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Acción principal: Abrir Detalle
                          if (nextStudent != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DriverStopDetailScreen(
                                      student: nextStudent,
                                      unitCode: unitCode,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF044837),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.ads_click),
                              label: const Text('DETALLE Y CONFIRMAR LLEGADA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            )
                          else
                             Center(
                               child: Column(
                                 children: [
                                   const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                   const SizedBox(height: 12),
                                   Text('¡Ruta Completada!', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold)),
                                   Text('No hay más paradas pendientes.', style: GoogleFonts.publicSans(color: Colors.grey)),
                                 ],
                               ),
                             ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen())),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerLow,
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('DETENER RECORRIDO', style: GoogleFonts.publicSans(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.route, 
                    label: 'Ruta', 
                    isActive: false, 
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()))
                  ),
                  _navItem(icon: Icons.map, label: 'Mapa', isActive: true, onTap: () {}),
                  _navItem(
                    icon: Icons.assignment_turned_in, 
                    label: 'Asistencia', 
                    isActive: false, 
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverAttendanceScreen()))
                  ),
                  _navItem(
                    icon: Icons.person, 
                    label: 'Perfil', 
                    isActive: false, 
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()))
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          )
        ],
      ),
    );
  }
}
