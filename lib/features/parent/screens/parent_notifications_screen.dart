import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_map_screen.dart';
import 'parent_history_screen.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);

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
                  // Title
                  Text(
                    'Notificaciones',
                    style: GoogleFonts.publicSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF191c1d),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantente al tanto del recorrido de tus hijos hoy.',
                    style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751)),
                  ),
                  const SizedBox(height: 32),

                  // Critical Alert
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFffdad6), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFFba1a1a), shape: BoxShape.circle),
                          child: const Icon(Icons.warning, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ALERTA: novedad en la vía',
                                    style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF93000a)),
                                  ),
                                  Text('AHORA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF93000a).withOpacity(0.6))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Se reporta tráfico pesado en la Av. Principal. El tiempo de llegada podría verse afectado.',
                                style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF93000a)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Normal Notifications
                  _buildNotification(
                    icon: Icons.directions_bus,
                    iconColor: _primary,
                    iconBg: const Color(0xFFd4e3ff),
                    title: 'Bus iniciando recorrido',
                    time: '07:15 AM',
                    subtitle: 'La unidad 24 ha comenzado su ruta hacia el colegio.',
                  ),
                  const SizedBox(height: 16),
                  _buildNotification(
                    icon: Icons.near_me,
                    iconColor: _primary,
                    iconBg: const Color(0xFFd9e4ee),
                    title: 'Bus a 600m de tu parada',
                    time: '07:32 AM',
                    subtitle: 'Prepárate, el bus está llegando a tu punto de encuentro.',
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 16),
                  _buildNotification(
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFFc1d9ff),
                    iconBg: _primaryContainer,
                    title: 'Tu hijo abordó el bus',
                    time: '07:35 AM',
                    subtitle: 'Ingreso confirmado mediante escaneo de credencial.',
                  ),

                  const SizedBox(height: 24),
                  // Separator
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('AYER', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildNotification(
                    icon: Icons.school,
                    iconColor: const Color(0xFF121d24),
                    iconBg: const Color(0xFFbdc8d1),
                    title: 'Llegada al colegio',
                    time: '16:45 PM',
                    subtitle: 'El bus ha finalizado su recorrido de retorno exitosamente.',
                    dimmed: true,
                  ),

                  const SizedBox(height: 64),
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
                        Text('BusGuardian', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w800, color: _primary, letterSpacing: -0.5))
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
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context, icon: Icons.home, label: 'Inicio', isActive: false, target: const ParentDashboardScreen()),
                    _navItem(context, icon: Icons.map, label: 'Mapa', isActive: false, target: const ParentMapScreen()),
                    _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: true, target: const ParentNotificationsScreen()),
                    _navItem(context, icon: Icons.history, label: 'Historial', isActive: false, target: const ParentHistoryScreen()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNotification({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String time,
    required String subtitle,
    bool isHighlighted = false,
    bool dimmed = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dimmed ? const Color(0xFFedeeef) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? Border(left: BorderSide(color: _primary, width: 4)) : null,
        boxShadow: dimmed ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Opacity(
        opacity: dimmed ? 0.8 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title, 
                          style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF191c1d)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF424751))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751)))
                ],
              ),
            )
          ],
        ),
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
        decoration: BoxDecoration(color: isActive ? const Color(0xFFdbeaFE) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? _primaryContainer : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? _primaryContainer : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
