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
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_member_utils.dart';
import '../../../core/services/incident_report_service.dart';
import 'widgets/map_hud.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  double _speed = 0.0;
  List<LatLng> _routePoints = [];
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  bool _isCalculatingRoute = false;
  bool _showHUD = true;
  final Set<String> _presentIds = {};
  static const LatLng _fallbackSchool = LatLng(-0.3485666414297856, -79.24772636139673);
  LatLng _schoolLocation = _fallbackSchool;
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
    _busIcon = await _createMarkerImageFromAsset('assets/images/autobus-escolar.png', 40);
    _schoolIcon = await _createMarkerImageFromAsset('assets/images/colegio.png', 45);
    _houseIcon = await _createMarkerImageFromAsset('assets/images/casa.png', 30);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createMarkerImageFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _speed = position.speed * 3.6;
          _updateRouteProgress();
        });
        
        // Cargar ruta inicialmente si la posición llegó y hay un viaje activo en progreso
        final profile = ref.read(userProfileProvider).value;
        final unitCode = normalizeUnitCode(profile?['unitCode'] as String?);
        final driverId = profile?['uid'];
        if (unitCode.isEmpty || driverId == null) return;
        final tripStatus = ref.read(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId))).value;
        if (tripStatus?['status'] == 'on_route' && _routePoints.isEmpty && !_isCalculatingRoute) {
          final students = ref.read(driverStudentsProvider(unitCode)).value ?? [];
          _getPolyline(LatLng(position.latitude, position.longitude), _schoolLocation, students);
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
    final unitCode = normalizeUnitCode(profile?['unitCode'] as String?);
    final driverId = profile?['uid'];
    if (unitCode.isEmpty || driverId == null) return;

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

    final tripStatus = ref.read(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId))).value;
    if (tripStatus?['status'] == 'on_route' && _speed >= IncidentReportService.speedLimitKmh) {
      IncidentReportService.reportSpeedIfNeeded(
        unitCode: unitCode,
        driverId: driverId,
        driverName: profile?['name'] ?? 'Conductor',
        speedKmh: _speed,
        routeName: tripStatus?['routeName'] as String?,
        lat: position.latitude,
        lng: position.longitude,
      );
    }
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
          final unitCode = normalizeUnitCode(profile?['unitCode'] as String?);
          final driverId = profile?['uid'];
          if (unitCode.isNotEmpty && driverId != null) {
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
    allPoints.add(_schoolLocation);

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
    super.build(context);
    return _buildMainMap();
  }

  void _showToast(String icon, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0D4D3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      )
    );
  }

  Widget _buildMainMap() {
    final profile = ref.watch(userProfileProvider).value;
    final unitCode = normalizeUnitCode(profile?['unitCode']?.toString());
    if (unitCode.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final company = ref.watch(companyByUnitProvider(unitCode)).asData?.value;
    final lat = company?['schoolLat'];
    final lng = company?['schoolLng'];
    if (lat is num && lng is num) {
      _schoolLocation = LatLng(lat.toDouble(), lng.toDouble());
    }
    final driverId = profile?['uid'] ?? 'UNKNOWN';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
    final students = studentsAsync.value ?? [];
    
    // Escuchamos reactivamente los cambios de estado del viaje
    ref.listen(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId)), (previous, next) {
      final wasActive = previous?.value?['status'] == 'on_route';
      final isActive = next.value?['status'] == 'on_route';

      if (wasActive && !isActive && _routePoints.isNotEmpty) {
        setState(() => _routePoints = []);
      }
      
      if (!wasActive && isActive && _routePoints.isEmpty && !_isCalculatingRoute && _currentPosition != null) {
        final startPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        _getPolyline(startPos, _schoolLocation, students);
      }
    });

    final tripStatusAsync = ref.watch(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId)));
    final isTripActive = tripStatusAsync.value?['status'] == 'on_route';
    final isModoIda = tripStatusAsync.value?['routeType'] == 'to_school';

    // Determinar próxima parada
    Map<String, dynamic>? nextStudent;
    double distToNext = 0;
    if (isTripActive && isModoIda) {
      for (var s in students) {
        if (!s.containsKey('stopLat') || s['status'] == 'absent') continue;
        if (!_presentIds.contains(s['id'])) {
          nextStudent = s;
          if (_currentPosition != null) {
            distToNext = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, s['stopLat'], s['stopLng']);
          }
          break;
        }
      }
    }

    // Calcular progreso
    double progress = 0;
    if (isTripActive && students.isNotEmpty) {
      int total = students.where((s) => s['status'] != 'absent').length;
      if (total > 0) progress = _presentIds.length / total;
    }

    final schoolTitle = company?['name'] as String? ?? 'Colegio';

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            trafficEnabled: _trafficEnabled,
            buildingsEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            initialCameraPosition: CameraPosition(target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : _schoolLocation, zoom: 15),
            onMapCreated: (c) {
              ref.read(mapControllerProvider.notifier).setController(c);
              if (_currentPosition != null) {
                c.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)));
                _hasCenteredInitially = true;
              }
            },
                  markers: _buildMarkers(students, isTripActive, schoolTitle),
            polylines: {
              if (_routePoints.isNotEmpty && isTripActive)
                Polyline(
                  polylineId: const PolylineId('route'), 
                  points: _currentPosition != null 
                      ? [LatLng(_currentPosition!.latitude, _currentPosition!.longitude), ..._routePoints]
                      : _routePoints, 
                  color: const Color(0xFFFFD600), // Amarillo ruta
                  width: 6, 
                  jointType: JointType.round, 
                  startCap: Cap.roundCap, 
                  endCap: Cap.roundCap
                ),
            },
          ),
          
          // 1. Header dinámico tipo HUD
          if (isTripActive && _showHUD)
            Positioned(
              top: 50, left: 16, right: 16,
              child: MapHUD(
                speedKmh: _speed,
                progressPercent: progress,
                eta: '${((students.length - _presentIds.length) * 5) + 15} min', // ETA simulado
                nextStopName: nextStudent?['studentName'],
              )
            ),

          // Controles en modo inactivo
          if (!isTripActive)
            Positioned(
              bottom: 40, left: 80, right: 80,
              child: ElevatedButton(
                onPressed: () => ref.read(driverNavigationProvider.notifier).setIndex(0),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4D3A), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
                child: Text('IR AL INICIO', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              )
            ),

          // Botón para finalizar recorrido
          if (isTripActive)
            Positioned(
              bottom: 40, left: 80, right: 80,
              child: ElevatedButton(
                onPressed: () => _finishTrip(unitCode, profile?['uid']),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
                child: Text('FINALIZAR VIAJE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              )
            ),



          // Controles Flotantes (Derecha)
          Positioned(
            bottom: isTripActive ? 120 : 100,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isTripActive) ...[
                  _actionBtn(Icons.speed_rounded, () => setState(() => _showHUD = !_showHUD), isActive: _showHUD),
                  const SizedBox(height: 12),
                  _actionBtn(Icons.warning_amber_rounded, () {
                     _sendTrafficAlert(unitCode, students);
                     _showToast('⚠️', 'Tráfico reportado a los padres');
                  }, color: Colors.orangeAccent),
                  const SizedBox(height: 12),
                ],
                _actionBtn(Icons.traffic_rounded, () => setState(() => _trafficEnabled = !_trafficEnabled), isActive: _trafficEnabled),
                const SizedBox(height: 12),
                _actionBtn(Icons.layers_rounded, () => setState(() => _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal)),
                const SizedBox(height: 12),
                _actionBtn(Icons.my_location_rounded, () { 
                  if (_currentPosition != null) {
                    ref.read(mapControllerProvider)?.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude))); 
                  }
                }, color: const Color(0xFFFFD600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap, {bool isActive = false, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0D4D3A) : color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Icon(icon, color: isActive ? Colors.white : const Color(0xFF0D4D3A), size: 24),
      ),
    );
  }

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

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> students, bool isTripActive, String schoolTitle) {
    Set<Marker> markers = {};

    markers.add(Marker(
      markerId: const MarkerId('school'),
      position: _schoolLocation,
      icon: _schoolIcon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(title: schoolTitle, snippet: 'Destino'),
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

    // Paradas planificadas por el administrador (visibles siempre que tengan coordenadas)
    for (var s in students) {
      if (s['stopLat'] != null && s['stopLng'] != null) {
        markers.add(Marker(
          markerId: MarkerId(s['id']?.toString() ?? s['studentName']?.toString() ?? 'student_${s.hashCode}'),
          position: LatLng((s['stopLat'] as num).toDouble(), (s['stopLng'] as num).toDouble()),
          icon: _houseIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: s['studentName'] ?? 'Estudiante'),
        ));
      }
    }
    return markers;
  }
}
