import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_map_screen.dart';
import 'parent_notifications_screen.dart';

class ParentHistoryScreen extends StatelessWidget {
  const ParentHistoryScreen({super.key});

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
                  // Title Section
                  Text(
                    'HISTORIAL DE RUTAS',
                    style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF727782)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Octubre 2023',
                    style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF191c1d), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 32),

                  // Calendar Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDayCard(day: 'LUN', date: '23'),
                        const SizedBox(width: 16),
                        _buildDayCard(day: 'MAR', date: '24'),
                        const SizedBox(width: 16),
                        _buildDayCard(day: 'MIE', date: '25', isActive: true),
                        const SizedBox(width: 16),
                        _buildDayCard(day: 'JUE', date: '26'),
                        const SizedBox(width: 16),
                        _buildDayCard(day: 'VIE', date: '27'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Summary Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
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
                                      Text('Resumen del Miércoles', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text('Ruta Escolar: Colegio Americano', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751))),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFd4e3ff), borderRadius: BorderRadius.circular(20)),
                                    child: Text('PRESENTE', style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004883))),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Grid Schedule
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: const Color(0xFFf3f4f5), borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.logout, size: 14, color: Color(0xFF727782)),
                                              const SizedBox(width: 4),
                                              Text('SALIDA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF727782))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('07:12', style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: _primary)),
                                          Text('Programada: 07:10', style: GoogleFonts.publicSans(fontSize: 11, color: const Color(0xFF424751))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: const Color(0xFFf3f4f5), borderRadius: BorderRadius.circular(16)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.login, size: 14, color: Color(0xFF727782)),
                                              const SizedBox(width: 4),
                                              Text('LLEGADA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF727782))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('07:58', style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: _primary)),
                                          Text('Programada: 08:00', style: GoogleFonts.publicSans(fontSize: 11, color: const Color(0xFF424751))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(color: Color(0xFFe1e3e4)),
                              const SizedBox(height: 16),
                              // Incident section
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('INCIDENCIAS REPORTADAS', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF727782))),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFffdcc4).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning, color: Color(0xFF6f3800)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tráfico Moderado', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2f1400))),
                                          Text('Retraso de 5 min en Av. Reforma debido a reparaciones viales.', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF703800))),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        // Driver Dipped Action Area
                        Container(
                          color: const Color(0xFFd4e3ff),
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=150&auto=format&fit=crop'), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CONDUCTOR', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF004883))),
                                    Text('Ricardo Mendoza', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF001c39)), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                child: Text('Ver Perfil', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFFedeeef), borderRadius: BorderRadius.circular(32)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.trending_up, color: _primary),
                              const SizedBox(height: 8),
                              Text('98%', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                              Text('Asistencia Mensual', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF424751))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFFedeeef), borderRadius: BorderRadius.circular(32)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.schedule, color: Color(0xFF6f3800)),
                              const SizedBox(height: 8),
                              Text('42 min', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                              Text('Tiempo Promedio', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF424751))),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 32),
                  // Descargar PDF Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: _primary.withOpacity(0.4),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text('DESCARGAR PDF', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: false, target: const ParentNotificationsScreen()),
                    _navItem(context, icon: Icons.history, label: 'Historial', isActive: true, target: const ParentHistoryScreen()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDayCard({required String day, required String date, bool isActive = false}) {
    return Container(
      width: 64, height: 80,
      decoration: BoxDecoration(
        color: isActive ? _primary : const Color(0xFFf3f4f5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isActive ? [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white.withOpacity(0.8) : const Color(0xFF424751))),
          const SizedBox(height: 4),
          Text(date, style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF191c1d))),
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
