import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/map_provider.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _studentIcon;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  double _speed = 0.0;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    try {
      _busIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(150, 150)), 'assets/images/bus_marker.png');
      _studentIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(100, 100)), 'assets/images/casa_marker.png');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading markers: $e');
    }
  }

  void _startTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 2)
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _speed = position.speed * 3.6;
        });
        
        // Actualizar Firebase para el Seguimiento del Padre
        final profile = ref.read(userProfileProvider).value;
        if (profile != null) {
          ref.read(trackingRepositoryProvider).updateDriverLocation(
            profile['unitCode'] ?? 'CAD31', profile['uid'] ?? 'ID', profile['name'] ?? 'Conductor', 
            position.latitude, position.longitude
          );
        }
      }
    });
  }

  // --- LÓGICA DE TRAZADO POR CALLES (DUMMY/PLACEHOLDER FOR DIRECTIONS API) ---
  void _createRoutePolylines(List<dynamic> students) {
    if (_currentPosition == null || students.isEmpty) return;

    List<LatLng> streetPath = [LatLng(_currentPosition!.latitude, _currentPosition!.longitude)];
    
    // Aquí, en una implementación real con API KEY activa, 
    // llamaríamos a Google Directions API para obtener los puntos por calles.
    // Simulamos un trazo que sigue las paradas.
    for (var s in students) {
      if (s['stopLat'] != null) streetPath.add(LatLng(s['stopLat'], s['stopLng']));
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: streetPath,
          color: const Color(0xFF0D4D3A), // Verde oscuro institucional
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.squareCap,
        )
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final unitCode = profile?['unitCode'] ?? 'CAD31';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. MAPA GOOGLE CON POLILÍNEAS
          _buildMap(unitCode),

          // 2. INDICADORES ESTADO (CONECTADO / ENTRADA / UNIDAD)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16, right: 16,
            child: Row(
              children: [
                _topStatusBadge(icon: Icons.wifi, label: 'Conectado', color: const Color(0xFF81C784)),
                const SizedBox(width: 8),
                _topStatusBadge(icon: Icons.directions_bus, label: 'Entrada', color: const Color(0xFFFFB74D)),
                const SizedBox(width: 8),
                _unitBadge(unitCode),
              ],
            ),
          ),

          // 3. CAJA TELEMETRÍA (DISEÑO IMAGEN REFERENCIA)
          Positioned(
             top: MediaQuery.of(context).padding.top + 60,
             left: 16,
             child: _telemetryBox(),
          ),

          // 4. ACCIONES LATERALES (Derecha)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 65,
            child: Column(
              children: [
                _sideActionBtn('Novedades'), const SizedBox(height: 10),
                _sideActionBtn('Llamar'), const SizedBox(height: 10),
                _sideActionBtn('Tomar Lista'),
              ],
            ),
          ),

          // 5. BOTONES ZOOM (Inferior Derecha)
          Positioned(
            bottom: 110, right: 16,
            child: Column(
              children: [
                _circularZoomBtn(Icons.add, () => ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.zoomIn())),
                const SizedBox(height: 8),
                _circularZoomBtn(Icons.remove, () => ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.zoomOut())),
              ],
            ),
          ),

          // 6. BOTONES EMERGENCIA Y CONTROL (Inferior)
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sos911Btn(),
                    _centerMapBtn(),
                  ],
                ),
                const SizedBox(height: 16),
                _finishTourWideBtn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(String unitCode) {
    if (_currentPosition == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF0D4D3A)));

    return Consumer(builder: (context, ref, _) {
       final routesStream = FirebaseFirestore.instance
          .collection('companies').doc(unitCode).collection('routes')
          .where('status', isEqualTo: 'active').limit(1).snapshots();

       return StreamBuilder<QuerySnapshot>(
          stream: routesStream,
          builder: (context, snapshot) {
            final Set<Marker> markers = {
              Marker(
                markerId: const MarkerId('driver'),
                position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                anchor: const Offset(0.5, 0.5),
              )
            };

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final routeData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final List students = routeData['assignedStudents'] ?? [];
              
              // Solo actualizamos polilíneas si es necesario
              Future.microtask(() => _createRoutePolylines(students));

              for (var s in students) {
                if (s['stopLat'] != null) {
                  markers.add(Marker(
                    markerId: MarkerId(s['id']),
                    position: LatLng(s['stopLat'], s['stopLng']),
                    icon: _studentIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(title: s['studentName']),
                  ));
                }
              }
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 17),
              onMapCreated: (c) => ref.read(mapControllerProvider.notifier).setController(c),
              markers: markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              style: _mapStyle,
            );
          }
       );
    });
  }

  Widget _topStatusBadge({required IconData icon, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.black87, size: 14), const SizedBox(width: 4),
          Text(label, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        ]),
      ),
    );
  }

  Widget _unitBadge(String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF0D4D3A), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.bus_alert, color: Colors.white, size: 14), const SizedBox(width: 4),
        Text('UNIDAD: $unit', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
      ]),
    );
  }

  Widget _telemetryBox() {
    return Container(
      padding: const EdgeInsets.all(12), width: 190,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _teleLine('Altitud', '${_currentPosition?.altitude.toStringAsFixed(1) ?? '2838.0'} m'),
        _teleLine('Precisión', '${_currentPosition?.accuracy.toStringAsFixed(1) ?? '25.6'} m'),
        _teleLine('Distancia', '0.06 Km.'),
        _teleLine('Velocidad', '${_speed.toStringAsFixed(1)} km/h'),
        _teleLine('Inicio', '13-04-2026:14:55:46'),
      ]),
    );
  }

  Widget _teleLine(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('$l: $v', style: GoogleFonts.publicSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)));

  Widget _sideActionBtn(String l) => Container(width: 110, height: 42, decoration: BoxDecoration(color: const Color(0xFF2196F3), borderRadius: BorderRadius.circular(15), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Center(child: Text(l, style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))));

  Widget _sos911Btn() => Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFC62828), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 15)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.phone_in_talk, color: Colors.white, size: 28), Text('911', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))]));

  Widget _centerMapBtn() => GestureDetector(onTap: () { if (_currentPosition != null) ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude))); }, child: Container(width: 60, height: 60, decoration: BoxDecoration(color: const Color(0xFFFFB74D), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]), child: const Icon(Icons.my_location, color: Colors.black87, size: 28)));

  Widget _finishTourWideBtn() => Container(width: double.infinity, height: 64, decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white24, width: 2), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12)]), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.stop_circle, color: Colors.white), const SizedBox(width: 12), Text('FINALIZAR RECORRIDO', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))]));

  Widget _circularZoomBtn(IconData i, VoidCallback t) => GestureDetector(onTap: t, child: Container(width: 45, height: 45, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(i, color: Colors.black54)));

  final String _mapStyle = '[{"featureType":"poi","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]}]';
}
