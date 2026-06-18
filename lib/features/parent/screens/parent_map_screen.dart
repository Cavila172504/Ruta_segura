import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'parent_nav_shell.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart';

class ParentMapScreen extends ConsumerStatefulWidget {
  const ParentMapScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends ConsumerState<ParentMapScreen>
    with AutomaticKeepAliveClientMixin {
  final Color _primaryColor = const Color(0xFFFFD600); // Yellow from mockup
  final Color _statusGreen = const Color(0xFFC8E6C9); // Mint/Green from mockup
  static const LatLng _fallbackSchool = LatLng(-0.3485666414297856, -79.24772636139673);

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _houseIcon;
  BitmapDescriptor? _schoolIcon;
  GoogleMapController? _mapController;

  // Auto-centrado en el bus al iniciar la ruta
  bool _hasCenteredOnBus = false;
  bool _followBus = true;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    try {
      _busIcon = BitmapDescriptor.bytes(await _getBytesFromAsset('assets/images/autobus-escolar.png', 40));
      _houseIcon = BitmapDescriptor.bytes(await _getBytesFromAsset('assets/images/casa.png', 30));
      _schoolIcon = BitmapDescriptor.bytes(await _getBytesFromAsset('assets/images/colegio.png', 45));
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
  bool get wantKeepAlive => widget.embeddedInShell;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.watch(remoteNotificationsListenerProvider);
    
    // 1. Lógica de Alerta de Proximidad Inteligente (500 metros) con ETA
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

            // Alerta si está a 500 metros o menos y aún no hemos avisado
            if (distance <= 500 && !_notifiedStudents.contains(sId)) {
              _notifiedStudents.add(sId); // Marcamos como avisado
              
              // Cálculo del ETA (Asumiendo 25 km/h en ciudad = ~6.9 m/s)
              // Tiempo (segundos) = distancia / velocidad
              int etaMinutos = (distance / 6.9 / 60).ceil();
              if (etaMinutos < 1) etaMinutos = 1;

              NotificationService().showLocalNotification(
                id: student.hashCode,
                title: '🚩 ¡El bus se acerca!',
                body: 'El bus está a ${distance.toInt()} metros. Llegará en aprox. $etaMinutos minuto(s).',
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
    final busHeading = ref.watch(busHeadingProvider).value ?? 0.0;
    final studentsAsync = ref.watch(parentStudentsProvider);
    final students = studentsAsync.value ?? [];
    
    // Status de ruta en tiempo real
    final busStatus = ref.watch(busStatusProvider).value ?? 'idle';
    final routeType = ref.watch(busRouteTypeProvider).value;
    final isRouteActive = busStatus == 'on_route';

    // ── AUTO-CENTRAR en el bus ──
    ref.listen<AsyncValue<LatLng?>>(liveBusLocationProvider, (previous, next) {
      final busLoc = next.value;
      if (busLoc != null && isRouteActive && _followBus) {
        if (_mapController != null) {
          if (!_hasCenteredOnBus) _hasCenteredOnBus = true;
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(busLoc, 16),
          );
        }
      }
    });

    final unitCode = ref.watch(activeUnitCodeProvider).asData?.value ?? '';
    final companyData = unitCode.isNotEmpty
        ? ref.watch(companyByUnitProvider(unitCode)).asData?.value
        : null;
    final lat = companyData?['schoolLat'];
    final lng = companyData?['schoolLng'];
    final schoolLoc = (lat is num && lng is num)
        ? LatLng(lat.toDouble(), lng.toDouble())
        : _fallbackSchool;
    final schoolTitle = companyData?['name'] as String? ?? 'Colegio';
    final polylines = ref.watch(activePolylinesProvider);

    // Resetear bandera cuando termine la ruta
    if (!isRouteActive) {
      _hasCenteredOnBus = false;
    }
    
    // Tomamos el primer estudiante para la cabecera (en caso de hermanos, podríamos rotarlos o elegir uno)
    final activeStudentName = students.isNotEmpty ? students.first['studentName'] : 'Estudiante';
    final homeMarkers = <Marker>{};
    for (final student in students) {
      final sLat = student['stopLat'];
      final sLng = student['stopLng'];
      if (sLat is num && sLng is num) {
        final id = student['id']?.toString() ?? student['studentName']?.toString() ?? 'home';
        homeMarkers.add(
          Marker(
            markerId: MarkerId('home_$id'),
            position: LatLng(sLat.toDouble(), sLng.toDouble()),
            icon: _houseIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: student['studentName']?.toString() ?? 'Parada'),
          ),
        );
      }
    }
    final homeLocation = homeMarkers.isNotEmpty
        ? homeMarkers.first.position
        : null;

    String statusLabel = 'Conductor aún no inicia';
    if (isRouteActive) {
      statusLabel = routeType == 'to_school' ? 'En camino al colegio' : 'En camino a casa';
    }

    String? etaLabel;
    if (isRouteActive && liveBusLocation != null && homeLocation != null) {
      final distance = Geolocator.distanceBetween(
        liveBusLocation.latitude,
        liveBusLocation.longitude,
        homeLocation.latitude,
        homeLocation.longitude,
      );
      final etaMin = (distance / 6.9 / 60).ceil().clamp(1, 120);
      etaLabel = 'ETA ~$etaMin min';
    }

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
                Row(
                  children: [
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
                            statusLabel,
                            style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: isRouteActive ? const Color(0xFF2E7D32) : Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    if (etaLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF90CAF9)),
                        ),
                        child: Text(
                          etaLabel,
                          style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1565C0)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                // Mapa Principal (Optimizado sin rutas)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: liveBusLocation ?? homeLocation ?? const LatLng(-0.2298, -78.5249),
                    zoom: 15,
                  ),
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  polylines: polylines,
                  markers: {
                    ...homeMarkers,
                    if (liveBusLocation != null && isRouteActive)
                      Marker(
                        markerId: const MarkerId('bus_marker'),
                        position: liveBusLocation,
                        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                        rotation: busHeading - 90.0,
                        anchor: const Offset(0.5, 0.5),
                        infoWindow: const InfoWindow(title: 'Unidad de Transporte'),
                      ),
                    Marker(
                      markerId: const MarkerId('school_marker'),
                      position: schoolLoc,
                      icon: _schoolIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(title: schoolTitle, snippet: 'Sede educativa'),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  child: FilterChip(
                    label: Text(_followBus ? 'Siguiendo bus' : 'Vista libre'),
                    selected: _followBus,
                    onSelected: (v) => setState(() => _followBus = v),
                  ),
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
                      // Centrar en Bus (solo si la ruta está activa)
                      if (isRouteActive)
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
      bottomNavigationBar: widget.embeddedInShell
          ? null
          : SafeArea(
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
              _navItem(context, icon: Icons.home_rounded, label: 'Inicio', isActive: false, index: 0),
              _navItem(context, icon: Icons.map_rounded, label: 'Mapa', isActive: true, index: 1),
              _navItem(context, icon: Icons.notifications_rounded, label: 'Notificaciones', isActive: false, index: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required int index}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ParentShellScreen(initialIndex: index)),
            );
          }
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
