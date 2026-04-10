import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_map_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_history_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  // Colores del tema Parent (Blue Theme)
  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);
  final Color _onSurface = const Color(0xFF191c1d);
  final Color _onSurfaceVariant = const Color(0xFF424751);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  Text(
                    'Buenos días, María',
                    style: GoogleFonts.publicSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lunes, 12 de Octubre',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Child Tracking Card (Bento Style)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: _primaryContainer.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))
                      ]
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Header del estudiante
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 64, height: 64,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFd9e4ee),
                                          borderRadius: BorderRadius.circular(16),
                                          image: const DecorationImage(
                                            image: NetworkImage('https://images.unsplash.com/photo-1544281679-42011668e1ab?q=80&w=200&auto=format&fit=crop'),
                                            fit: BoxFit.cover,
                                          )
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mateo',
                                            style: GoogleFonts.publicSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: _onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Colegio San Agustín',
                                            style: GoogleFonts.publicSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _onSurfaceVariant,
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'BUS EN CAMINO',
                                      style: GoogleFonts.publicSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Ruta Asignada
                              Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe7e8e9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.route, color: _primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RUTA ASIGNADA',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: _onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Expreso Norte - B42',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _onSurface,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Llegada estimada
                              Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe7e8e9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.schedule, color: _primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'LLEGADA ESTIMADA',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: _onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        '07:45 AM (en 12 min)',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _onSurface,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        // Action Button
                        Container(
                          color: const Color(0xFFd4e3ff), // primary-fixed
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentMapScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryContainer, // We use container as close to gradient
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.map, size: 20),
                            label: Text(
                              'VER EN MAPA',
                              style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Notifications Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actividad Reciente',
                        style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentNotificationsScreen()));
                        },
                        child: Text(
                          'VER TODO',
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: _primary,
                          ),
                        ),
                      )
                    ],
                  ),

                  // Notifications List
                  _buildNotificationItem(
                    icon: Icons.departure_board,
                    iconColor: const Color(0xFF5b666e),
                    iconBg: const Color(0xFFd9e4ee),
                    title: 'El bus ha iniciado el recorrido',
                    subtitle: 'Hace 5 minutos • Parada Central',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    icon: Icons.warning,
                    iconColor: const Color(0xFF703800), // tertiary variant
                    iconBg: const Color(0xFFffdcc4), // tertiary fixed
                    title: 'Ligero retraso en tráfico',
                    subtitle: 'Hace 15 minutos • Av. Las Américas',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    icon: Icons.done_all,
                    iconColor: const Color(0xFF5b666e),
                    iconBg: const Color(0xFFd9e4ee),
                    title: 'Asignación de ruta confirmada',
                    subtitle: 'Hoy, 06:00 AM • Sistema',
                  ),

                  const SizedBox(height: 60),
                ],
              ),
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
                    Icon(Icons.notifications, color: Colors.grey.shade500),
                  ],
                ),
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
                  _navItem(context, icon: Icons.home, label: 'Inicio', isActive: true, target: const ParentDashboardScreen()),
                  _navItem(context, icon: Icons.map, label: 'Mapa', isActive: false, target: const ParentMapScreen()),
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

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.publicSans(fontSize: 11, color: _onSurfaceVariant),
                )
              ],
            ),
          )
        ],
      ),
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
