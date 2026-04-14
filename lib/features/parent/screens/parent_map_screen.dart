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
  final Color _primaryColor = const Color(0xFFFFD600); // Yellow from mockup
  final Color _statusGreen = const Color(0xFFC8E6C9); // Mint/Green from mockup
  
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _houseIcon;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    try {
      _busIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(120, 120)),
        'assets/images/autobus-escolar.png',
      );
      _houseIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)),
        'assets/images/casa.png',
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error cargando iconos: $e');
    }
  }

  void _centerOnLocation(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(location));
  }

  // Registro para no repetir la notificación de proximidad muchas veces
  final Set<String> _notifiedStudents = {};

  @override
  Widget build(BuildContext context) {
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
    
    // Tomamos el primer estudiante para la cabecera (en caso de hermanos, podríamos rotarlos o elegir uno)
    final activeStudentName = students.isNotEmpty ? students.first['studentName'] : 'Estudiante';
    final homeLocation = students.isNotEmpty && students.first['stopLat'] != null
        ? LatLng(students.first['stopLat'] as double, students.first['stopLng'] as double)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MONITOREO',
          style: GoogleFonts.merriweather( // O un font sans-serif fuerte
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.0
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sub-barra de Estado (Gabriel Flores - Ruta Activa)
          Container(
            color: _statusGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeStudentName.toUpperCase(),
                  style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                Row(
                  children: [
                    Text(
                      'Ruta Activa',
                      style: GoogleFonts.publicSans(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                  ],
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
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.map_outlined, color: Colors.black54),
                  ),
                ),

                // Map View Controls (Botones Flotantes de Bus y Casa)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: Column(
                    children: [
                      // Centrar en Bus
                      GestureDetector(
                        onTap: () {
                          if (liveBusLocation != null) _centerOnLocation(liveBusLocation);
                        },
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.directions_bus, color: Colors.black, size: 35),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Centrar en Casa
                      GestureDetector(
                        onTap: () {
                          if (homeLocation != null) _centerOnLocation(homeLocation);
                        },
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50), // Vibrant Green matching new house
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.home, color: Colors.white, size: 35),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
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
