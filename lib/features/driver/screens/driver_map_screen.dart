import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/map_provider.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  int _currentIndex = 1;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _studentIcon;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  double _speed = 0.0;
  Set<Polyline> _polylines = {};
  final Set<String> _notifiedStudents = {};
  final LatLng _cadeLocation = const LatLng(-0.2523, -79.1754);
  
  // Llave de API desde el manifiesto (AIzaSyD_Ouc48di910vgKcylLJyueeNPwIfoSnQ)
  final String _googleApiKey = "AIzaSyBRXBhHluPGhrGNTC9cj03aGut7Q6jkd_U";
  DateTime? _lastRouteUpdate;

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  Future<void> _initSystem() async {
    await _loadIcons();
    await _checkPermissions();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    try {
      final bus = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(80, 80)), 'assets/images/bus_marker.png');
      final house = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(50, 50)), 'assets/images/casa_marker.png');
      if (mounted) setState(() { _busIcon = bus; _studentIcon = house; });
    } catch (e) {
      _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      _studentIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    Position? pos = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
    if (mounted) setState(() => _currentPosition = pos);
    _startTracking();
  }

  void _startTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10)
    ).listen((pos) {
      if (mounted) {
        setState(() { _currentPosition = pos; _speed = (pos.speed < 0) ? 0 : pos.speed * 3.6; });
        _updateFirebase(pos);
        _checkNear(pos);
      }
    });
  }

  void _updateFirebase(Position pos) {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      ref.read(trackingRepositoryProvider).updateDriverLocation(
        profile['unitCode'] ?? 'CADE', profile['uid'] ?? 'ID', profile['name'] ?? 'Conductor', pos.latitude, pos.longitude
      );
    }
  }

  void _checkNear(Position pos) {
    final profile = ref.read(userProfileProvider).value;
    final unitCode = profile?['unitCode'] ?? 'CADE';
    FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('routes').where('status', isEqualTo: 'active').limit(1).get().then((snap) {
      if (snap.docs.isNotEmpty) {
        final students = snap.docs.first['assignedStudents'] as List;
        final shift = snap.docs.first['shift'] ?? 'MATUTINA';
        
        // Solo actualizar polilíneas cada 30 segundos para optimizar recursos
        if (_lastRouteUpdate == null || DateTime.now().difference(_lastRouteUpdate!).inSeconds > 30) {
          _updateRealRoadLines(students, shift);
          _lastRouteUpdate = DateTime.now();
        }

        for (var s in students) {
          if (s['stopLat'] != null && !_notifiedStudents.contains(s['id'])) {
            double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, s['stopLat'], s['stopLng']);
            if (dist < 600) { _notify(s['id'], s['studentName'], unitCode); _notifiedStudents.add(s['id']); }
          }
        }
      }
    });
  }

  Future<void> _notify(String id, String name, String unit) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': id, 'title': '¡Bus Cerca!', 'body': 'Unidad $unit cerca de $name.', 'type': 'proximity', 'createdAt': FieldValue.serverTimestamp(), 'status': 'pending'
    });
  }

  // --- MOTOR DE NAVEGACIÓN PROFESIONAL ---
  
  Future<void> _updateRealRoadLines(List students, String shift) async {
    if (_currentPosition == null) return;
    
    // 1. Determinar Destino Final
    bool isRetorno = shift.toUpperCase().contains('VESPERTINA') || shift.toUpperCase().contains('RETORNO');
    LatLng origin = isRetorno ? _cadeLocation : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    LatLng destination = isRetorno ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : _cadeLocation;

    // 2. Si no hay alumnos con GPS, hacer ruta directa
    var gpsStudents = students.where((s) => s['stopLat'] != null).toList();
    if (gpsStudents.isEmpty) {
      _drawFallbackLines([origin, destination]);
      return;
    }

    // 3. Llamar a Google Directions API
    try {
      // Construir Waypoints (paradas intermedias)
      String waypoints = "optimize:true|";
      for (var s in gpsStudents) {
        waypoints += "${s['stopLat']},${s['stopLng']}|";
      }

      final url = "https://maps.googleapis.com/maps/api/directions/json"
          "?origin=${origin.latitude},${origin.longitude}"
          "&destination=${destination.latitude},${destination.longitude}"
          "&waypoints=$waypoints"
          "&key=$_googleApiKey";

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final points = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> roadPoints = _decodePolyline(points);
        
        if (mounted) {
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('real_road'),
                points: roadPoints,
                color: const Color(0xFF0D4D3A),
                width: 6,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              )
            };
          });
        }
      } else {
        debugPrint("Google API Error: ${data['status']}");
        _drawFallbackLines([origin, ...gpsStudents.map((s) => LatLng(s['stopLat'], s['stopLng'])), destination]);
      }
    } catch (e) {
      debugPrint("Error fetching road navigation: $e");
      _drawFallbackLines([origin, destination]);
    }
  }

  void _drawFallbackLines(List<LatLng> points) {
    if (mounted) {
      setState(() {
        _polylines = { Polyline(polylineId: const PolylineId('fallback'), points: points, color: const Color(0xFF0D4D3A), width: 5) };
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  // --- INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final unitCode = profile?['unitCode'] ?? 'CADE';

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const Center(child: Text('RUTA')),
          _currentPosition == null ? const Center(child: CircularProgressIndicator()) : _buildMainMap(unitCode),
          const Center(child: Text('ASISTENCIA')),
          const Center(child: Text('PERFIL')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFFFD600),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fork_right_outlined), label: 'RUTA'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'MAPA'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_ind_outlined), label: 'ASISTENCIA'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PERFIL'),
        ],
      ),
    );
  }

  Widget _buildMainMap(String unitCode) {
    final stream = FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('routes').where('status', isEqualTo: 'active').limit(1).snapshots();

    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snap) {
            final Set<Marker> markers = {
              Marker(markerId: const MarkerId('bus'), position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), anchor: const Offset(0.5, 0.5)),
              Marker(markerId: const MarkerId('cade'), position: _cadeLocation, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'COLEGIO CADE'))
            };
            if (snap.hasData && snap.data!.docs.isNotEmpty) {
              final r = snap.data!.docs.first.data() as Map<String, dynamic>;
              final List students = r['assigned_students'] ?? r['assignedStudents'] ?? [];
              for (var s in students) if (s['stopLat'] != null) markers.add(Marker(markerId: MarkerId(s['id']), position: LatLng(s['stopLat'], s['stopLng']), icon: _studentIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: InfoWindow(title: s['studentName'])));
            }
            return GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 15),
              onMapCreated: (c) => ref.read(mapControllerProvider.notifier).setController(c),
              markers: markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            );
          }
        ),
        _buildHud(unitCode),
      ],
    );
  }

  Widget _buildHud(String unit) => Stack(children: [
    Positioned(top: 45, left: 16, right: 16, child: Row(children: [_badge(Icons.wifi, 'Online', Colors.green[400]!), const SizedBox(width: 8), _badge(Icons.directions_bus, 'Ruta', Colors.orange[400]!), const SizedBox(width: 8), _unitBadge('UNIDAD CADE')])),
    Positioned(top: 100, left: 16, child: _teleBox()),
    Positioned(right: 16, top: 105, child: Column(children: [_sideBtn('Novedades'), const SizedBox(height: 10), _sideBtn('Llamar'), const SizedBox(height: 10), _sideBtn('Lista')])),
    Positioned(bottom: 100, right: 16, child: _gpsBtn()),
    Positioned(bottom: 20, left: 16, right: 16, child: _finishBtn()),
  ]);

  Widget _badge(IconData i, String l, Color c) => Expanded(child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 16), const SizedBox(width: 4), Text(l, style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold))])));
  Widget _unitBadge(String u) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0D4D3A), borderRadius: BorderRadius.circular(12)), child: Text(u, style: GoogleFonts.publicSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)));
  Widget _teleBox() => Container(padding: const EdgeInsets.all(12), width: 180, decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Velocidad: ${_speed.toStringAsFixed(1)} km/h', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), Text('Altitud: ${_currentPosition?.altitude.toStringAsFixed(0) ?? '--'} m', style: const TextStyle(color: Colors.white, fontSize: 11))]));
  Widget _sideBtn(String l) => Container(width: 105, height: 42, decoration: BoxDecoration(color: const Color(0xFF2196F3), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(l, style: GoogleFonts.publicSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))));
  Widget _gpsBtn() => GestureDetector(onTap: () { if (_currentPosition != null) ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude))); }, child: Container(width: 55, height: 55, decoration: BoxDecoration(color: const Color(0xFFFFB74D), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.my_location)));
  Widget _finishBtn() => Container(width: double.infinity, height: 58, decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(25)), child: Center(child: Text('FINALIZAR RECORRIDO', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))));
}
