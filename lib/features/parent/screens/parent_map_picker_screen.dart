import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';

class ParentMapPickerScreen extends StatefulWidget {
  const ParentMapPickerScreen({super.key});

  @override
  State<ParentMapPickerScreen> createState() => _ParentMapPickerScreenState();
}

class _ParentMapPickerScreenState extends State<ParentMapPickerScreen> {
  GoogleMapController? _controller;
  LatLng _centerPosition = const LatLng(-0.180653, -78.467834); // Quito por defecto
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialLocation();
  }

  Future<void> _checkInitialLocation() async {
    final locationService = LocationService();
    final pos = await locationService.getCurrentPosition();
    if (pos != null) {
      if (mounted) {
        setState(() {
          _centerPosition = LatLng(pos.latitude, pos.longitude);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UBICACIÓN DE LA CASA', style: GoogleFonts.publicSans(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _centerPosition, zoom: 16),
            onMapCreated: (controller) => _controller = controller,
            onCameraMove: (position) {
              _centerPosition = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Lo personalizamos abajo
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          
          // PIN CENTRAL (El usuario mueve el mapa, no el pin)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Offset para que apunte exacto al centro
              child: Icon(Icons.location_on, color: Colors.red, size: 50),
            ),
          ),
          
          // CAPA DE INSTRUCCIÓN
          Positioned(
            top: 24, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
                ]
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Arrastra el mapa hasta que el marcador rojo apunte exactamente a la casa o parada.',
                      style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // BOTÓN FLOTANTE MI UBICACIÓN
          Positioned(
            bottom: 120, right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primaryContainer),
              onPressed: () async {
                final pos = await LocationService().getCurrentPosition();
                if (pos != null && _controller != null) {
                  _controller!.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
                }
              },
            ),
          ),

          // BOTON DE CONFIRMAR
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _centerPosition);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                child: Text('CONFIRMAR PARADA', style: GoogleFonts.publicSans(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
