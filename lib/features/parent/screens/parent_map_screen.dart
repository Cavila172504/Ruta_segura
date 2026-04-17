import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_notifications_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/notification_provider.dart';

import '../../../core/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart';

class ParentMapScreen extends ConsumerStatefulWidget {
  const ParentMapScreen({super.key});

  @override
  ConsumerState<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends ConsumerState<ParentMapScreen> {
  final Color _primaryColor = const Color(0xFFFFD600); // Yellow from mockup
  final Color _statusGreen = const Color(0xFFC8E6C9); // Mint/Green from mockup
  final LatLng _cadeLocation = const LatLng(-0.3485666414297856, -79.24772636139673);
  
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _houseIcon;
  BitmapDescriptor? _schoolIcon;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    try {
      _busIcon = BitmapDescriptor.fromBytes(await _getBytesFromAsset('assets/images/autobus-escolar.png', 130));
      _houseIcon = BitmapDescriptor.fromBytes(await _getBytesFromAsset('assets/images/casa.png', 100));
      _schoolIcon = BitmapDescriptor.fromBytes(await _getBytesFromAsset('assets/images/colegio.png', 120));
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error cargando iconos: $e');
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void _centerOnLocation(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));
  }

  // Registro para no repetir la notificación de proximidad muchas veces
  final Set<String> _notifiedStudents = {};

  @override
  Widget build(BuildContext context) {
    ref.watch(remoteNotificationsListenerProvider);
    // 1. Lógica de Alerta de Proximidad (600 metros)
    ref.listen(liveBusLocationProvider, (previous, next) {
      final busLoc = next.value;
      final students = ref.read(parentStudentsProvider).value ?? [];
      
      if (busLoc != null) {
        for (var student in students) {
          final sId = student['id'] ?? student['studentName'];
          final sLat = student['stopLat'] as double?;
          final sLng = student['stopLng'] as double?;
          
          if (sLat != null && sLng != null) {
            final distance = Geolocator.distanceBetween(
              busLoc.latitude, busLoc.longitude,
              sLat, sLng,
            );

            // Alerta si está a menos de 600 metros y aún no hemos avisado
            if (distance < 600 && !_notifiedStudents.contains(sId)) {
              _notifiedStudents.add(sId); // Marcamos como avisado
              
              NotificationService().showLocalNotification(
                id: student.hashCode,
                title: '🚩 ¡El bus está cerca!',
                body: 'Está a ${distance.toInt()}m de la parada de ${student['studentName']}. Es momento de salir.',
              );
            } 
            // Si el bus se aleja más de 2km, reseteamos para cuando vuelva en el siguiente turno (tarde)
            else if (distance > 2000 && _notifiedStudents.contains(sId)) {
              _notifiedStudents.remove(sId);
            }
          }
        }
      }
    });

    final liveBusLocation = ref.watch(liveBusLocationProvider).value;
    final studentsAsync = ref.watch(parentStudentsProvider);
    final students = studentsAsync.value ?? [];
    
    // Status de ruta en tiempo real
    final busStatus = ref.watch(busStatusProvider).value ?? 'idle';
    final isRouteActive = busStatus == 'on_route';
    
    // Tomamos el primer estudiante para la cabecera (en caso de hermanos, podríamos rotarlos o elegir uno)
    final activeStudentName = students.isNotEmpty ? students.first['studentName'] : 'Estudiante';
    final homeLocation = students.isNotEmpty && students.first['stopLat'] != null
        ? LatLng(students.first['stopLat'] as double, students.first['stopLng'] as double)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 4,
        shadowColor: Colors.black26,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.satellite_alt_rounded, color: Colors.black87, size: 24),
            const SizedBox(width: 10),
            Text(
              'MONITOREO EN VIVO',
              style: GoogleFonts.publicSans(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sub-barra de Estado (Gabriel Flores - Ruta Activa) - Mejorada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                      child: const Icon(Icons.person, size: 18, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      activeStudentName.toUpperCase(),
                      style: GoogleFonts.publicSans(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF191c1d)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRouteActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isRouteActive ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: isRouteActive ? const Color(0xFF4CAF50) : Colors.grey.shade500, 
                          shape: BoxShape.circle,
                          boxShadow: isRouteActive ? const [BoxShadow(color: Color(0xFF4CAF50), blurRadius: 4)] : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRouteActive ? 'Ruta Activa' : 'En Espera',
                        style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: isRouteActive ? const Color(0xFF2E7D32) : Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                // Mapa Principal
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: liveBusLocation ?? homeLocation ?? const LatLng(-0.2298, -78.5249),
                    zoom: 15,
                  ),
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  markers: {
                    // Marcador Casa Estudiante
                    if (homeLocation != null)
                      Marker(
                        markerId: const MarkerId('home_marker'),
                        position: homeLocation,
                        icon: _houseIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                        anchor: const Offset(0.5, 0.5),
                        infoWindow: InfoWindow(title: 'Ubicación de $activeStudentName'),
                      ),
                    
                    // Marcador Bus Real-time
                    if (liveBusLocation != null)
                      Marker(
                        markerId: const MarkerId('bus_marker'),
                        position: liveBusLocation,
                        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                        anchor: const Offset(0.5, 0.5),
                        infoWindow: const InfoWindow(title: 'Unidad de Transporte'),
                      ),

                    // Marcador Colegio CADE
                    Marker(
                      markerId: const MarkerId('cade_marker'),
                      position: _cadeLocation,
                      icon: _schoolIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: const InfoWindow(title: 'Unidad Educativa CADE', snippet: 'Destino Final'),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Map Legend Overlay (Botón Mapa)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.map_outlined, color: Colors.black54),
                  ),
                ),

                // Map View Controls (Botones Flotantes de Bus y Casa)
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: Column(
                    children: [
                      // Centrar en Bus
                      GestureDetector(
                        onTap: () {
                          if (liveBusLocation != null) _centerOnLocation(liveBusLocation);
                        },
                        child: Container(
                          width: 65, height: 65,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset('assets/images/autobus-escolar.png', fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Centrar en Casa
                      GestureDetector(
                        onTap: () {
                          if (homeLocation != null) _centerOnLocation(homeLocation);
                        },
                        child: Container(
                          width: 65, height: 65,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Image.asset('assets/images/casa.png', fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // +/- Zoom Controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.black54),
                              onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                            ),
                            Container(width: 20, height: 1, color: Colors.grey.shade200),
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.black54),
                              onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // --- BARRA DE NAVEGACIÓN INFERIOR RESTAURADA ---
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(context, icon: Icons.home, label: 'Inicio', isActive: false, target: const ParentDashboardScreen()),
              _navItem(context, icon: Icons.map, label: 'Mapa', isActive: true, target: const ParentMapScreen()),
              _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: false, target: const ParentNotificationsScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget target}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF004782) : Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.publicSans(
                fontSize: 9, 
                fontWeight: FontWeight.w800, 
                color: isActive ? const Color(0xFF004782) : Colors.grey.shade400
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
