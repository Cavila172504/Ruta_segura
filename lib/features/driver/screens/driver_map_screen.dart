import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  MapType _currentMapType = MapType.normal;
  bool _isCalculatingRoute = false;
  final LatLng _cadeLocation = const LatLng(-0.3485666414297856, -79.24772636139673);
  final String _googleApiKey = "AIzaSyBRXBhHluPGhrGNTc9cj03aGut7Q6jkd_U";

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _schoolIcon;
  BitmapDescriptor? _houseIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startTracking();
  }

  Future<void> _loadIcons() async {
    _busIcon = await _createMarkerImageFromAsset('assets/images/autobus-escolar.png', 100);
    _schoolIcon = await _createMarkerImageFromAsset('assets/images/colegio.png', 100);
    _houseIcon = await _createMarkerImageFromAsset('assets/images/casa.png', 80);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createMarkerImageFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }

  bool _hasCenteredInitially = false;

  void _updateRouteProgress() {
    if (_routePoints.isEmpty || _currentPosition == null) return;

    int closestIndex = 0;
    double minDistance = double.infinity;

    int searchLimit = _routePoints.length > 50 ? 50 : _routePoints.length;
    for (int i = 0; i < searchLimit; i++) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude,
        _routePoints[i].latitude, _routePoints[i].longitude
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Si el conductor se desvía más de 150 metros, limpiamos la ruta para forzar recálculo
    if (minDistance > 150) {
      _routePoints.clear();
      return;
    }

    if (minDistance < 60 && closestIndex > 0) {
      _routePoints.removeRange(0, closestIndex);
    }
  }

  Future<void> _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _speed = position.speed * 3.6;
          _updateRouteProgress();
        });
        
        // Cargar ruta inicialmente si la posición llegó y hay un viaje activo en progreso
        final profile = ref.read(userProfileProvider).value;
        final unitCode = profile?['unitCode'] ?? 'CAD31';
        final driverId = profile?['uid'];
        if (driverId != null) {
          final tripStatus = ref.read(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId))).value;
          if (tripStatus?['status'] == 'on_route' && _routePoints.isEmpty && !_isCalculatingRoute) {
            final students = ref.read(driverStudentsProvider(unitCode)).value ?? [];
            _getPolyline(LatLng(position.latitude, position.longitude), _cadeLocation, students);
          }
        }

        _updateFirebase(position);

        if (!_hasCenteredInitially && ref.read(mapControllerProvider) != null) {
          ref.read(mapControllerProvider)!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16));
          _hasCenteredInitially = true;
        }
      }
    });
  }

  Future<void> _updateFirebase(Position position) async {
    final profile = ref.read(userProfileProvider).value;
    final unitCode = profile?['unitCode'] ?? 'CAD31';
    final driverId = profile?['uid'];
    if (driverId == null) return;

    // Actualizamos en live_tracking según tu estructura de Firebase
    // NO sobreescribimos 'status' aquí – se controla desde el Dashboard (on_route / finished)
    await FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('live_tracking').doc(driverId).set({
      'driverId': driverId,
      'driverName': profile?['name'] ?? 'Conductor',
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': _speed,
      'heading': _getBusHeading(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _getPolyline(LatLng origin, LatLng destination, List<dynamic> students) async {
    if (_isCalculatingRoute) return;
    _isCalculatingRoute = true;
    
    try {
      String waypoints = "";
      List<dynamic> validStudents = students.where((s) => s['stopLat'] != null && s['stopLng'] != null).toList();
      if (validStudents.isNotEmpty) {
        waypoints = "&waypoints=optimize:true";
        for (var s in validStudents) {
          waypoints += "|${s['stopLat']},${s['stopLng']}";
        }
      }

      final String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '$waypoints'
          '&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        List<PointLatLng> allPoints = [];
        
        // Extraer los puntos detallados de cada 'step' en cada 'leg' de la ruta
        // Esto garantiza que la línea siga cada curva de la calle en alta resolución
        for (var leg in data['routes'][0]['legs']) {
          for (var step in leg['steps']) {
            String encoded = step['polyline']['points'];
            allPoints.addAll(PolylinePoints.decodePolyline(encoded));
          }
        }

        if (mounted) {
          setState(() {
            _routePoints = allPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
          });
          // Ajustar cámara para mostrar toda la ruta
          _fitRouteOnMap(origin, destination, validStudents);
          
          // Sincronización en tiempo real: Guardar la nueva ruta para el Padre y Web Admin
          final profile = ref.read(userProfileProvider).value;
          final unitCode = profile?['unitCode'] ?? 'CAD31';
          final driverId = profile?['uid'];
          if (driverId != null) {
            String fullRouteJson = jsonEncode(_routePoints.map((p) => [p.latitude, p.longitude]).toList());
            FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('live_tracking').doc(driverId).set({
              'fullRouteJson': fullRouteJson,
              'routeUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      debugPrint('Error en Polyline: $e');
    } finally {
      _isCalculatingRoute = false;
    }
  }

  /// Centra el mapa en la ubicación del bus a un zoom cómodo para conducir
  void _fitRouteOnMap(LatLng origin, LatLng destination, List<dynamic> students) {
    final controller = ref.read(mapControllerProvider);
    if (controller == null) return;

    // Centrar en la posición actual del conductor con zoom cercano
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(origin, 15),
    );
  }

  /// Muestra toda la ruta completa (bus + paradas + colegio) ajustando el zoom
  void _showFullRoute() {
    final controller = ref.read(mapControllerProvider);
    if (controller == null || _routePoints.isEmpty) return;

    // Incluir posición actual y colegio
    final List<LatLng> allPoints = [..._routePoints];
    if (_currentPosition != null) {
      allPoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    allPoints.add(_cadeLocation);

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  Future<void> _sendTrafficAlert(String unitCode, List<dynamic> students) async {
    try {
      int count = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var student in students) {
        final parentUid = student['parentId'] as String?;
        if (parentUid != null) {
          final notifRef = FirebaseFirestore.instance.collection('users').doc('parents').collection('members').doc(parentUid).collection('notifications').doc();
          batch.set(notifRef, {
            'title': '⚠️ Retraso por Tráfico',
            'message': 'El transporte reporta tráfico inusual. Es posible que llegue un poco más tarde.',
            'timestamp': Timestamp.now(),
            'type': 'traffic_alert',
            'isRead': false,
          });
          count++;
          if (count >= 400) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            count = 0;
          }
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Alerta de tráfico enviada'), backgroundColor: Colors.blue));
    } catch (e) {
      debugPrint('Error sending alert: $e');
    }
  }

  Future<void> _finishTrip(String unitCode, String? driverId) async {
    if (driverId == null) return;
    await FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('live_tracking').doc(driverId).update({
      'status': 'finished',
      'isActive': false,
      'finishedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) ref.read(driverNavigationProvider.notifier).setIndex(0);
  }

  Future<void> _moveCamera(double dx, double dy) async {
    final controller = ref.read(mapControllerProvider);
    if (controller != null) await controller.animateCamera(CameraUpdate.scrollBy(dx, dy));
  }

  Future<void> _zoomCamera(bool zoomIn) async {
    final controller = ref.read(mapControllerProvider);
    if (controller != null) {
      if (zoomIn) {
        await controller.animateCamera(CameraUpdate.zoomIn());
      } else {
        await controller.animateCamera(CameraUpdate.zoomOut());
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainMap();
  }

  Widget _buildMainMap() {
    final profile = ref.watch(userProfileProvider).value;
    final unitCode = profile?['unitCode'] ?? 'CAD31';
    final driverId = profile?['uid'] ?? 'UNKNOWN';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
    
    // Escuchamos reactivamente los cambios de estado del viaje
    ref.listen(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId)), (previous, next) {
      final wasActive = previous?.value?['status'] == 'on_route';
      final isActive = next.value?['status'] == 'on_route';

      // Limpiar ruta si el viaje terminó
      if (wasActive && !isActive && _routePoints.isNotEmpty) {
        setState(() => _routePoints = []);
      }
      
      // Trazar ruta si el viaje acaba de iniciar
      if (!wasActive && isActive && _routePoints.isEmpty && !_isCalculatingRoute && _currentPosition != null) {
        final startPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        _getPolyline(startPos, _cadeLocation, studentsAsync.value ?? []);
      }
    });

    final tripStatusAsync = ref.watch(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId)));
    final isTripActive = tripStatusAsync.value?['status'] == 'on_route';

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            initialCameraPosition: CameraPosition(target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : _cadeLocation, zoom: 15),
            onMapCreated: (c) {
              ref.read(mapControllerProvider.notifier).setController(c);
              if (_currentPosition != null) {
                c.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)));
                _hasCenteredInitially = true;
              }
            },
            markers: _buildMarkers(studentsAsync.value ?? [], isTripActive),
            polylines: {
              if (_routePoints.isNotEmpty && isTripActive)
                Polyline(
                  polylineId: const PolylineId('route'), 
                  points: _currentPosition != null 
                      ? [LatLng(_currentPosition!.latitude, _currentPosition!.longitude), ..._routePoints]
                      : _routePoints, 
                  color: const Color(0xFF2196F3), 
                  width: 6, 
                  jointType: JointType.round, 
                  startCap: Cap.roundCap, 
                  endCap: Cap.roundCap
                ),
            },
          ),
          Positioned(
            top: 50, left: 16, right: 16,
            child: Row(
              children: [
                _topBadge(isTripActive ? 'Wifi On' : 'Offline', isTripActive ? Colors.green.shade600 : Colors.grey, Icons.wifi),
                const SizedBox(width: 8),
                _topBadge('Ruta', isTripActive ? Colors.orange.shade700 : Colors.grey, Icons.directions_bus_rounded),
                const SizedBox(width: 8),
                _topBadge('UNIDAD $unitCode', const Color(0xFF0D4D3A), Icons.tag_rounded),
              ],
            ),
          ),
          Positioned(top: 110, left: 16, child: _teleBox()),
          if (isTripActive) ...[
            Positioned(top: 110, right: 16, child: _novedadesBtn(() => _sendTrafficAlert(unitCode, studentsAsync.value ?? []))),
            Positioned(bottom: 25, left: 50, right: 50, child: _finishBtn(() => _finishTrip(unitCode, profile?['uid']))),
          ] else ...[
            Positioned(bottom: 25, left: 50, right: 50, child: _goToDashboardBtn(context)),
          ],
          // Controles flotantes derechos agrupados (Evita solapamiento)
          Positioned(
            bottom: isTripActive ? 105 : 45,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isTripActive && _routePoints.isNotEmpty) ...[
                  _fullRouteBtn(),
                  const SizedBox(height: 12),
                ],
                _zoomButtons(),
                const SizedBox(height: 12),
                _mapTypeBtn(),
                const SizedBox(height: 12),
                _gpsBtn(),
              ],
            ),
          ),
          // D-Pad Control
          Positioned(bottom: isTripActive ? 105 : 45, left: 16, child: _dpad()),
        ],
      ),
    );
  }

  Widget _topBadge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 5)]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 12), const SizedBox(width: 4), Text(text.toUpperCase(), style: GoogleFonts.publicSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))]),
  );

  Widget _novedadesBtn(VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
    child: Text('Novedades', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
  );

  Widget _finishBtn(VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 8),
    child: Center(child: Text('FINALIZAR RECORRIDO', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5))),
  );

  Widget _goToDashboardBtn(BuildContext context) => ElevatedButton(
    onPressed: () {
      ref.read(driverNavigationProvider.notifier).setIndex(0);
    },
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4D3A), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 8),
    child: Center(child: Text('IR AL INICIO PARA EMPEZAR', style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5))),
  );

  Widget _dpad() => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.arrow_drop_up_rounded, color: Color(0xFF0D4D3A), size: 28), onPressed: () => _moveCamera(0, -150), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.arrow_left_rounded, color: Color(0xFF0D4D3A), size: 28), onPressed: () => _moveCamera(-150, 0), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 15),
            IconButton(icon: const Icon(Icons.arrow_right_rounded, color: Color(0xFF0D4D3A), size: 28), onPressed: () => _moveCamera(150, 0), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ],
        ),
        IconButton(icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D4D3A), size: 28), onPressed: () => _moveCamera(0, 150), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ],
    ),
  );

  Widget _zoomButtons() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _controlBtn(Icons.add_rounded, () => _zoomCamera(true)),
      const SizedBox(height: 6),
      _controlBtn(Icons.remove_rounded, () => _zoomCamera(false)),
    ],
  );

  Widget _controlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]), child: Icon(icon, color: const Color(0xFF0D4D3A), size: 22)),
  );

  /// Botón para ver toda la ruta completa en el mapa
  Widget _fullRouteBtn() => GestureDetector(
    onTap: _showFullRoute,
    child: Container(
      width: 45, height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF0D4D3A),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFF0D4D3A).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: const Icon(Icons.route_rounded, color: Color(0xFFFFD600), size: 22),
    ),
  );

  Widget _mapTypeBtn() => GestureDetector(
    onTap: () => setState(() => _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : (_currentMapType == MapType.satellite ? MapType.terrain : MapType.normal)),
    child: Container(width: 45, height: 45, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD600), width: 1.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]), child: const Icon(Icons.layers_rounded, color: Color(0xFF0D4D3A), size: 22)),
  );

  Widget _gpsBtn() => GestureDetector(
    onTap: () { if (_currentPosition != null) ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude))); },
    child: Container(width: 45, height: 45, decoration: const BoxDecoration(color: Color(0xFFFFD600), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)]), child: const Icon(Icons.my_location, color: Color(0xFF0D4D3A), size: 22)),
  );

  Widget _teleBox() => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Velocidad: ${_speed.toStringAsFixed(1)} km/h', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), Text('Altitud: ${_currentPosition?.altitude.toStringAsFixed(0) ?? "--"} m', style: const TextStyle(color: Colors.white, fontSize: 9))]));

  double _getBusHeading() {
    double heading = _currentPosition?.heading ?? 0;
    
    // Use the route to determine the bus heading if possible
    if (_routePoints.isNotEmpty && _currentPosition != null) {
      LatLng targetPoint = _routePoints.first;
      // Look slightly ahead on the route for a smoother direction
      if (_routePoints.length > 2) {
        targetPoint = _routePoints[2];
      } else if (_routePoints.length > 1) {
        targetPoint = _routePoints[1];
      }
      heading = Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        targetPoint.latitude,
        targetPoint.longitude,
      );
    }
    
    return heading;
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> students, bool isTripActive) {
    Set<Marker> markers = {};

    // Siempre mostrar el colegio como destino
    markers.add(Marker(
      markerId: const MarkerId('school'),
      position: _cadeLocation,
      icon: _schoolIcon ?? BitmapDescriptor.defaultMarker,
      infoWindow: const InfoWindow(title: 'Colegio CADE', snippet: 'Destino'),
    ));

    // Siempre mostrar la ubicación del bus (conductor) si tenemos posición
    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        // We subtract 90 because the bus image natively faces East (90 degrees).
        rotation: _getBusHeading() - 90.0,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Mi Ubicación'),
      ));
    }

    // Mostrar las paradas de los estudiantes cuando el viaje está activo
    if (isTripActive) {
      for (var s in students) {
        if (s['stopLat'] != null && s['stopLng'] != null) {
          markers.add(Marker(
            markerId: MarkerId(s['id']?.toString() ?? s['studentName']?.toString() ?? 'student_${s.hashCode}'),
            position: LatLng(s['stopLat'] as double, s['stopLng'] as double),
            icon: _houseIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: s['studentName'] ?? 'Estudiante'),
          ));
        }
      }
    }
    return markers;
  }
}
