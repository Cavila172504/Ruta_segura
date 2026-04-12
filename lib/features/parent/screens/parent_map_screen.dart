import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_history_screen.dart';
import 'parent_proximity_alert_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/map_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/screens/login_screen.dart';

class ParentMapScreen extends ConsumerWidget {
  const ParentMapScreen({super.key});

  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Mapa Interactivo Real Background
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, _) {
                final locationAsync = ref.watch(currentLocationStreamProvider);
                
                return locationAsync.when(
                  data: (position) {
                    final routePoints = ref.watch(busRouteProvider);
                    final polylines = ref.watch(activePolylinesProvider);
                    final liveBusLocation = ref.watch(liveBusLocationProvider).value;
                    final studentStop = ref.watch(studentStopProvider).value;
                    
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(target: liveBusLocation ?? routePoints.first, zoom: 14),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      polylines: polylines,
                      markers: {
                        if (studentStop != null)
                          Marker(
                            markerId: const MarkerId('home'),
                            position: studentStop,
                            infoWindow: const InfoWindow(title: 'Mi Parada (Hogar)'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          ),
                        if (liveBusLocation != null)
                          Marker(
                            markerId: const MarkerId('bus'),
                            position: liveBusLocation,
                            infoWindow: const InfoWindow(title: 'Ruta Escolar en tiempo real'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const ParentProximityAlertScreen(),
                              );
                            },
                          ),
                      },
                      onMapCreated: (controller) {
                        try{
                           ref.read(mapControllerProvider.notifier).setController(controller);
                        } catch(e){}
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Habilita el GPS', style: GoogleFonts.publicSans())),
                );
              },
            ),
          ),

          // Top App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRect(
              child: Container(
                color: Colors.white.withOpacity(0.85),
                padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: _primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'BusGuardian',
                          style: GoogleFonts.publicSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                            letterSpacing: -0.5,
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.logout, color: Colors.grey.shade600),
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),



          // Map Controls
          Positioned(
            right: 24,
            top: 120,
            child: Column(
              children: [
                _mapControlButton(Icons.my_location),
                const SizedBox(height: 12),
                _mapControlButton(Icons.layers),
              ],
            ),
          ),

          // Bus Status Toggle Button
          Positioned(
            left: 24,
            bottom: 120,
            child: GestureDetector(
              onTap: () => _showBusDetails(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ESTADO DEL BUS',
                      style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: _primaryContainer.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -8))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context, icon: Icons.home, label: 'Inicio', isActive: false, target: const ParentDashboardScreen()),
                    _navItem(context, icon: Icons.map, label: 'Mapa', isActive: true, target: const ParentMapScreen()),
                    _navItem(context, icon: Icons.notifications, label: 'Alertas', isActive: false, target: const ParentNotificationsScreen()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Icon(icon, color: _primary),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget target}) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFdbeaFE) : Colors.transparent, // blue-100 fallback
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _primaryContainer : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.publicSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isActive ? _primaryContainer : Colors.grey.shade400,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showBusDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTADO DEL BUS',
                        style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: const Color(0xFF556068)),
                      ),
                      Text(
                        'Llega en 5 min',
                        style: GoogleFonts.publicSans(fontSize: 28, fontWeight: FontWeight.w900, color: _primary, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFd9e4ee), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text('PLACA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('ABC-1234', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFf3f4f5), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=250&auto=format&fit=crop'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Roberto Mendez', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Conductor Certificado', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751))),
                        ],
                      ),
                    ),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
                      child: const Icon(Icons.call, color: Colors.white),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
