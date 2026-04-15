import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/map_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/navigation_provider.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  double _speed = 0.0;
  List<LatLng> _routePoints = [];
  MapType _currentMapType = MapType.normal; // Estado para el tipo de mapa
  final LatLng _cadeLocation = const LatLng(-0.3485666414297856, -79.24772636139673);
  final String _googleApiKey = "AIzaSyBRXBhHluPGhrGNTc9cj03aGut7Q6jkd_U";
  
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _houseIcon;
  BitmapDescriptor? _schoolIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _checkPermissions();
  }

  Future<void> _loadCustomIcons() async {
    try {
      _busIcon = await _getAssetIcon('assets/images/autobus-escolar.png', 110);
      _houseIcon = await _getAssetIcon('assets/images/casa.png', 80);
      _schoolIcon = await _getAssetIcon('assets/images/colegio.png', 130);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading icons: $e');
    }
  }

  Future<BitmapDescriptor> _getAssetIcon(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _startTracking();
    }
  }

  void _startTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _speed = position.speed * 3.6;
        });
        _updateFirebase(position);
      }
    });
  }

  Future<void> _updateFirebase(Position position) async {
    final profile = ref.read(userProfileProvider).value;
    final unitCode = profile?['unitCode'] as String?;
    if (unitCode == null) return;

    final routeSt = await ref.read(activeRouteProvider(unitCode).future);
    if (routeSt?['isActive'] != true) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(unitCode)
        .collection('live_tracking')
        .doc('realtime')
        .set({
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': _speed,
      'heading': position.heading,
      'status': 'on_route',
      'last_update': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getPolyline(LatLng origin, LatLng destination, List<dynamic> students) async {
    // CORRECCIÓN: Se requiere la apiKey en el constructor en la v3.1.0
    PolylinePoints polylinePoints = PolylinePoints(apiKey: _googleApiKey);
    
    try {
      List<PolylineWayPoint> wayPoints = students.map((s) => PolylineWayPoint(
        location: "${s['stopLat']},${s['stopLng']}",
        stopOver: true
      )).toList();

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
          wayPoints: wayPoints,
          optimizeWaypoints: false,
        ),
      );

      if (result.points.isNotEmpty) {
        if (mounted) {
          setState(() {
            _routePoints = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _buildMainMap();
  }

  Widget _buildMainMap() {
    final profile = ref.watch(userProfileProvider).value;
    final unitCode = profile?['unitCode'] ?? 'CADE';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
              zoom: 15
            ),
            onMapCreated: (c) => ref.read(mapControllerProvider.notifier).setController(c),
            markers: _buildMarkers(studentsAsync.value ?? []), 
            polylines: {
              if (_routePoints.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('definitive_route'),
                  points: _routePoints,
                  color: const Color(0xFFFFD600),
                  width: 8,
                  jointType: JointType.round,
                ),
            },
          ),
          Positioned(top: 50, left: 16, right: 16, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_teleBox(), _unitBadge(unitCode)])),
          Positioned(bottom: 100, right: 16, child: _mapTypeBtn()),
          Positioned(bottom: 30, right: 16, child: _gpsBtn()),
        ],
      ),
    );
  }

  Widget _mapTypeBtn() => GestureDetector(
    onTap: () {
      setState(() {
        if (_currentMapType == MapType.normal) {
          _currentMapType = MapType.satellite;
        } else if (_currentMapType == MapType.satellite) {
          _currentMapType = MapType.terrain;
        } else {
          _currentMapType = MapType.normal;
        }
      });
    },
    child: Container(
      width: 56, height: 56, 
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD600), width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: const Icon(Icons.layers_rounded, color: Color(0xFF0D4D3A)),
    ),
  );

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> students) {
    Set<Marker> markers = {};
    markers.add(Marker(markerId: const MarkerId('school_cade'), position: _cadeLocation, icon: _schoolIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'Colegio CADE')));
    if (_currentPosition != null) {
      markers.add(Marker(markerId: const MarkerId('current_bus'), position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), rotation: _currentPosition!.heading, flat: true, anchor: const Offset(0.5, 0.5)));
    }
    for (var s in students) {
      markers.add(Marker(markerId: MarkerId(s['id'] ?? 'std'), position: LatLng(s['stopLat'] as double, s['stopLng'] as double), icon: _houseIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), infoWindow: InfoWindow(title: s['studentName'] ?? 'Estudiante')));
    }
    return markers;
  }

  Widget _teleBox() => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Velocidad: ${_speed.toStringAsFixed(1)} km/h', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)), Text('Altitud: ${_currentPosition?.altitude.toStringAsFixed(0) ?? "--"} m', style: const TextStyle(color: Colors.white, fontSize: 10))]));
  Widget _unitBadge(String u) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF0D4D3A), borderRadius: BorderRadius.circular(12)), child: Text(u, style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.bold)));
  Widget _gpsBtn() => GestureDetector(onTap: () { if (_currentPosition != null) ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude))); }, child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: Color(0xFFFFD600), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: const Icon(Icons.my_location, color: Color(0xFF0D4D3A))));
}
