import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/map_provider.dart';

class DriverRouteCreatorScreen extends ConsumerStatefulWidget {
  const DriverRouteCreatorScreen({super.key});

  @override
  ConsumerState<DriverRouteCreatorScreen> createState() => _DriverRouteCreatorScreenState();
}

class _DriverRouteCreatorScreenState extends ConsumerState<DriverRouteCreatorScreen> {
  final List<dynamic> _routeSequence = [];
  final Color _primaryColor = const Color(0xFF0D4D3A);
  final Color _accentColor = const Color(0xFFFFD600);
  
  Set<Marker> _markers = {};
  bool _isSaving = false;
  final int _currentIndex = 0;

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _houseIcon;
  BitmapDescriptor? _schoolIcon;
  final LatLng _cadeLocation = const LatLng(-0.3485666414297856, -79.24772636139673);

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final unitCode = profileAsync.value?['unitCode'] as String? ?? 'CAD31';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
    final locationAsync = ref.watch(currentLocationStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          // MAPA DE CONSTRUCCIÓN
          Positioned.fill(
            child: studentsAsync.when(
              data: (students) {
                _updateMarkers(students, locationAsync.value);
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: locationAsync.value != null 
                      ? LatLng(locationAsync.value!.latitude, locationAsync.value!.longitude) 
                      : const LatLng(-0.2298, -78.5249),
                    zoom: 15,
                  ),
                  onMapCreated: (c) => ref.read(mapControllerProvider.notifier).setController(c),
                  markers: _markers,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // HEADER INSTRUCTIVO
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildHeader(),
          ),

          // PANEL LATERAL DE SECUENCIA (Lista de paradas agregadas)
          Positioned(
            left: 16,
            bottom: 120,
            child: _buildSequenceCounter(),
          ),

          // BOTÓN DE ACCIÓN: FINALIZAR RUTA
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: _buildBottomAction(unitCode),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 15,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          Navigator.pop(context); // Salir del modo arquitecto antes de navegar
          // La navegación real ocurre en las otras pantallas
        },
        selectedItemColor: const Color(0xFF0D4D3A),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        unselectedLabelStyle: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'DASHBOARD'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'MAPA'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'ALUMNOS'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PERFIL'),
        ],
      ),
    );
  }

  void _updateMarkers(List<dynamic> students, dynamic myPos) {
    final Set<Marker> newMarkers = {};
    
    // Icono Colegio
    newMarkers.add(Marker(
      markerId: const MarkerId('school_marker'),
      position: _cadeLocation,
      icon: _schoolIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Unidad Educativa CADE'),
    ));

    // Icono para estudiantes disponibles (Casitas)
    for (var s in students) {
      if (s['stopLat'] != null) {
        final bool isAdded = _routeSequence.any((item) => item['id'] == s['id']);
        
        newMarkers.add(Marker(
          markerId: MarkerId(s['id']),
          position: LatLng(s['stopLat'], s['stopLng']),
          icon: isAdded 
            ? (_houseIcon != null ? _houseIcon! : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
            : (_houseIcon != null ? _houseIcon! : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
          onTap: () {
            if (!isAdded) _addStopToSequence(s);
          },
          infoWindow: InfoWindow(
            title: s['studentName'],
            snippet: isAdded ? 'PARADA #${_routeSequence.indexWhere((it) => it['id'] == s['id']) + 1}' : 'Toca para agregar a la ruta',
          ),
        ));
      }
    }
    
    setState(() => _markers = newMarkers);
  }

  void _addStopToSequence(dynamic student) {
    setState(() {
      _routeSequence.add(student);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${student['studentName']} agregado como parada #${_routeSequence.length}'),
        duration: const Duration(seconds: 1),
        backgroundColor: _primaryColor,
      )
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryColor, _primaryColor.withValues(alpha: 0.8)]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MODO ARQUITECTO', style: GoogleFonts.publicSans(color: _accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('Construyendo Nueva Ruta', style: GoogleFonts.publicSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceCounter() {
    if (_routeSequence.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Row(
        children: [
          const Icon(Icons.pin_drop, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '${_routeSequence.length} PARADAS SELECCIONADAS',
            style: GoogleFonts.publicSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(String unitCode) {
    return ElevatedButton(
      onPressed: (_routeSequence.isEmpty || _isSaving) ? null : () => _saveNewRoute(unitCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentColor,
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: _accentColor.withValues(alpha: 0.4),
      ),
      child: _isSaving 
        ? const CircularProgressIndicator()
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload_rounded),
              const SizedBox(width: 12),
              Text('FINALIZAR Y SUBIR RUTA', style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
    );
  }

  Future<void> _saveNewRoute(String unitCode) async {
    setState(() => _isSaving = true);
    
    try {
      final String routeName = 'RUTA DINÁMICA - ${DateTime.now().hour}:${DateTime.now().minute}';
      
      await FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('routes').add({
        'name': routeName,
        'unitId': unitCode,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'driver',
        'assigned_students': _routeSequence, // Usamosassigned_students para web_admin
        'status': 'active',
        'shift': 'MATUTINA'
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('¡ÉXITO!', style: GoogleFonts.publicSans(color: _accentColor, fontWeight: FontWeight.w900)),
            content: Text('La ruta ha sido creada y sincronizada con el panel administrativo.', style: GoogleFonts.publicSans(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text('CONFIRMAR', style: GoogleFonts.publicSans(color: _accentColor, fontWeight: FontWeight.w900)),
              )
            ],
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
