import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_history_screen.dart';
import 'parent_proximity_alert_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/map_provider.dart';

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
                    final latLng = LatLng(position.latitude, position.longitude);
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(target: latLng, zoom: 16),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        try{
                           ref.read(mapControllerProvider.notifier).state = controller;
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.share, color: _primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Compartir',
                                style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: _primary),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.notifications, color: Colors.grey.shade600),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          // House Marker
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.45,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primary, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                  child: const Icon(Icons.home, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black12)]),
                  child: Text('Hogar', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
                )
              ],
            ),
          ),

          // Bus Marker (Interactive to show alert)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.55,
            left: MediaQuery.of(context).size.width * 0.25,
            child: GestureDetector(
              onTap: () {
                // Show Proximity Alert Modal
                showDialog(
                  context: context,
                  builder: (context) => const ParentProximityAlertScreen(),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6f3800), // tertiary color
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF6f3800).withOpacity(0.4), blurRadius: 20)],
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                    ),
                    child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black12)]),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _primary, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Ruta Escolar', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
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

          // Floating Bottom Sheet Info Card
          Positioned(
            bottom: 110, // Above bottom nav
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: _primaryContainer.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 8))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900, color: _primary, letterSpacing: -0.5),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.near_me, size: 14, color: Color(0xFF424751)),
                                    const SizedBox(width: 4),
                                    Text('A 1.2 km de distancia', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF424751))),
                                  ],
                                )
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFFd9e4ee), borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                children: [
                                  Text('PLACA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text('ABC-1234', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Driver Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFf3f4f5), borderRadius: BorderRadius.circular(24)),
                          child: Row(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=150&auto=format&fit=crop'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Roberto Mendez', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('Conductor Certificado', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF424751))),
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
                        )
                      ],
                    ),
                  ),
                  // Progress Line
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: const Color(0xFFe7e8e9),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
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
                  _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: false, target: const ParentNotificationsScreen()),
                  _navItem(context, icon: Icons.history, label: 'Historial', isActive: false, target: const ParentHistoryScreen()),
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
}
