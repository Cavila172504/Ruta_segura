import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'driver_dashboard_screen.dart';
import 'driver_stop_detail_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/map_provider.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import 'package:geolocator/geolocator.dart';

class DriverMapScreen extends ConsumerWidget {
  const DriverMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Interactive Map Area
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, _) {
                // Sincronizar ubicación con Firestore
                ref.listen(currentLocationStreamProvider, (previous, next) async {
                  final position = next.value;
                  if (position != null) {
                    final profile = await ref.read(userProfileProvider.future);
                    final unitCode = profile?['unitCode'] as String? ?? 'UNIDAD-GENERICA';
                    
                    ref.read(trackingRepositoryProvider).updateDriverLocation(
                      unitCode, 
                      position.latitude, 
                      position.longitude,
                    );
                  }
                });

                final locationAsync = ref.watch(currentLocationStreamProvider);
                
                LatLng initialPos = defaultInitialLocation;
                if (locationAsync.hasValue) {
                  initialPos = LatLng(locationAsync.value!.latitude, locationAsync.value!.longitude);
                }

                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: initialPos, zoom: 16),
                      myLocationEnabled: locationAsync.hasValue,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        ref.read(mapControllerProvider.notifier).setController(controller);
                      },
                    ),
                    if (locationAsync.hasError)
                      Positioned(
                        top: 140,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'GPS deshabilitado - Usando ubicación base',
                              style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF086B53).withOpacity(0.2), // teal shadow top
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.surface
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // El Bus Marker estático ha sido reemplazado por `myLocationEnabled: true` del GPS nativo.

          // Top Header (Top Navigation Anchor)
          Positioned(
            top: 0, left: 0, right: 0, // Using same logic as Dashboard
            child: Container(
              color: const Color(0xFF044837), // Dark teal (teal-900)
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 24,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: NetworkImage('https://i.pravatar.cc/150?u=carlos'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'RUTASEGURA',
                        style: GoogleFonts.publicSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Top Floating Status Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 24, right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                    spreadRadius: -12,
                  )
                ]
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA0F3D4), // secondary-container
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.route, color: Color(0xFF167159)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RUTA ACTIVA',
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Ruta 42 - En progreso',
                            style: GoogleFonts.publicSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA0F3D4).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary, shape: BoxShape.circle
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ACTIVO',
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: const Color(0xFF167159),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Emergency Button
          Positioned(
            right: 24,
            bottom: 300, // Above bottom sheet
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ]
                  ),
                  child: const Icon(Icons.warning, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),

          // Bottom Sheet Detail
          Positioned(
            bottom: 64,
            left: 0, right: 0,
            child: Consumer(
              builder: (context, ref, _) {
                final profileAsync = ref.watch(userProfileProvider);
                final unitCode = profileAsync.value?['unitCode'] as String? ?? '';
                final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
                final driverLocation = ref.watch(currentLocationStreamProvider).value;

                final students = studentsAsync.value ?? [];
                // Tomamos el primer estudiante como "siguiente parada"
                final nextStudent = students.isNotEmpty ? students.first : null;

                final studentName = nextStudent?['studentName'] as String? ?? 'Sin paradas';
                final stopLat = nextStudent?['stopLat'] as double?;
                final stopLng = nextStudent?['stopLng'] as double?;

                // Calcular distancia real
                double? distanceKm;
                int? etaMin;
                if (driverLocation != null && stopLat != null && stopLng != null) {
                  final distM = Geolocator.distanceBetween(
                    driverLocation.latitude, driverLocation.longitude,
                    stopLat, stopLng,
                  );
                  distanceKm = distM / 1000;
                  etaMin = (distM / 300).ceil();
                }

                // Coordenadas formateadas como referencia
                final stopRef = (stopLat != null && stopLng != null)
                    ? '${stopLat.toStringAsFixed(4)}, ${stopLng.toStringAsFixed(4)}'
                    : 'Sin ubicación';

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                        spreadRadius: -5,
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          width: 48, height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentsAsync.isLoading
                                            ? 'CARGANDO...'
                                            : 'SIGUIENTE PARADA',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        studentName,
                                        style: GoogleFonts.publicSans(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.onSurface,
                                          letterSpacing: -0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              stopRef,
                                              style: GoogleFonts.publicSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        text: distanceKm != null
                                            ? '${distanceKm.toStringAsFixed(1)} '
                                            : '-- ',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.secondary,
                                          letterSpacing: -1,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'KM',
                                            style: GoogleFonts.publicSans(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ]
                                      ),
                                    ),
                                    Text(
                                      etaMin != null
                                          ? 'ESTIMADO: $etaMin MIN'
                                          : 'CALCULANDO...',
                                      style: GoogleFonts.publicSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Barra de progreso (total estudiantes)
                            if (students.isNotEmpty)
                              SizedBox(
                                height: 24,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA0F3D4),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        const done = 1; // Futuro: paradas completadas
                                        final total = students.length;
                                        final fraction = done / total;
                                        return Container(
                                          width: constraints.maxWidth * fraction,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Confirmar llegada
                            ElevatedButton.icon(
                              onPressed: nextStudent != null
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const DriverStopDetailScreen()),
                                      )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: const Color(0xFF221B00),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.check_circle, size: 24),
                              label: Text(
                                'CONFIRMAR LLEGADA',
                                style: GoogleFonts.publicSans(
                                    fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DriverDashboardScreen()),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.surfaceContainerLow,
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'DETENER RECORRIDO',
                                style: GoogleFonts.publicSans(
                                    fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.route, 
                    label: 'Ruta', 
                    isActive: false, 
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()))
                  ),
                  _navItem(icon: Icons.map, label: 'Mapa', isActive: true, onTap: () {}),
                  _navItem(icon: Icons.assignment_turned_in, label: 'Asistencia', isActive: false, onTap: () {}),
                  _navItem(icon: Icons.person, label: 'Perfil', isActive: false, onTap: () {}),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          )
        ],
      ),
    );
  }
}
