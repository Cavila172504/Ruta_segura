import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_routes_screen.dart';
import 'admin_students_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  final Color _primary = const Color(0xFF3B309E);
  final Color _primaryContainer = const Color(0xFF534AB7);
  final Color _surface = const Color(0xFFFCF8FF);
  final Color _onSurface = const Color(0xFF1C1B22);
  final Color _surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color _errorContainer = const Color(0xFFFFDAD6);
  final Color _onErrorContainer = const Color(0xFF93000A);
  final Color _error = const Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    // For web/desktop, we'll keep it simple with a top app bar and scrollable body.
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.security, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('RutaSegura Admin', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.account_circle, color: _primary), onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resumen General', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: _onSurface)),
                Text('LIVE FEED • UTC-5', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 800 ? 1.5 : 1.2,
                  children: [
                    _buildMetricCard('Rutas activas', '12', Icons.directions_bus, _primary, '+2', _surfaceContainerLowest, _onSurface),
                    _buildMetricCard('Buses en marcha', '08', Icons.speed, _primary, 'Live', _surfaceContainerLowest, _onSurface),
                    _buildMetricCard('Alumnos transportados hoy', '432', Icons.school, _primary, '86%', _surfaceContainerLowest, _onSurface),
                    _buildMetricCard('Incidentes activos', '02', Icons.warning, _error, 'Crítico', _errorContainer, _onErrorContainer, isError: true),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),

            // Main Content Area
            LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 800;
                Widget activeTrips = _buildActiveTrips();
                Widget monitoring = _buildMonitoringPanel();

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: activeTrips),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: monitoring),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      activeTrips,
                      const SizedBox(height: 24),
                      monitoring,
                    ],
                  );
                }
              }
            ),
          ],
        ),
      ),
      // Mobile Bottom Nav
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color iconColor, String badge, Color bgColor, Color textColor, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: isError ? Colors.red.shade100 : _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor)),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isError ? Colors.red.shade900 : Colors.grey.shade700)),
              Text(value, style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.bold, color: textColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveTrips() {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF6F2FC), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Viajes Activos', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.tune, color: Colors.grey), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.search, color: Colors.grey), onPressed: () {}),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildTripItem('Ruta Norte - Colegio San José', 'Salida: 06:45 AM • Conductor: Carlos M.', Icons.route, _primary, 'En curso', _primaryContainer),
                _buildTripItem('Ruta Sur - El Trébol', 'Salida: 07:00 AM • Conductor: Elena R.', Icons.route, _primary, 'En curso', _primaryContainer),
                _buildTripItem('Ruta Express - Av. Central', 'Retraso 15 min - Tráfico pesado', Icons.traffic, _error, 'En curso', _primaryContainer, isWarning: true),
                _buildTripItem('Ruta Escolar - Sector Este', 'Salida: 07:15 AM • Conductor: Roberto L.', Icons.route, _primary, 'Preparando', Colors.grey.shade600),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTripItem(String title, String subtitle, IconData icon, Color iconColor, String status, Color statusColor, {bool isWarning = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: isWarning ? Border(left: BorderSide(color: _error, width: 4)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFF0ECF6), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface)),
                  Row(
                    children: [
                      Icon(isWarning ? Icons.warning : Icons.schedule, size: 14, color: isWarning ? _error : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: isWarning ? _error : Colors.grey.shade600, fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal)),
                    ],
                  )
                ],
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
            child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildMonitoringPanel() {
    return Column(
      children: [
        // Satelite map view
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _primaryContainer, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monitoreo Satelital', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Todos los sistemas operativos. Tiempo de respuesta promedio: 4s.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 24),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black26, 
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken)) // Placeholder
                ),
                child: const Center(child: Icon(Icons.my_location, color: Colors.white54, size: 48)),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Latest Reports
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Últimos Reportes', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: _onSurface)),
              const SizedBox(height: 16),
              _buildReportItem('Desvío en Ruta 12', 'Hace 5 minutos • Bus #104', Icons.feedback, _error),
              const SizedBox(height: 16),
              _buildReportItem('Mantenimiento Bus #09 completado', 'Hace 22 minutos • Taller Central', Icons.check_circle, _primary),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildReportItem(String title, String time, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface)),
            Text(time, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
          ],
        )
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, 'Dashboard', Icons.dashboard, true, const AdminDashboardScreen()),
            _navItem(context, 'Rutas', Icons.directions_bus, false, const AdminRoutesScreen()),
            _navItem(context, 'Estudiantes', Icons.school, false, const AdminStudentsScreen()),
            _navItem(context, 'Reportes', Icons.analytics, false, const AdminReportsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, IconData icon, bool isActive, Widget target) {
    return GestureDetector(
      onTap: () {
        if (!isActive) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? _primaryContainer.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? _primaryContainer : Colors.grey.shade500),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? _primaryContainer : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
