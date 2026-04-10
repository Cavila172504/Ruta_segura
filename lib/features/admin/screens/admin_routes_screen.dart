import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_screen.dart';
import 'admin_students_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_route_edit_screen.dart';

class AdminRoutesScreen extends StatelessWidget {
  const AdminRoutesScreen({super.key});

  final Color _primary = const Color(0xFF3B309E);
  final Color _primaryContainer = const Color(0xFF534AB7);
  final Color _surface = const Color(0xFFFCF8FF);
  final Color _onSurface = const Color(0xFF1C1B22);
  final Color _surfaceContainerLowest = const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('RutaSegura Admin', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: _primary), onPressed: () {}),
          IconButton(icon: Icon(Icons.account_circle, color: _primary), onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión de Rutas', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: _onSurface)),
            const SizedBox(height: 24),

            // Search and filters
            LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 800;
                Widget searchBox = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFEBE6F0), borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Buscar rutas, conductores...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                      border: InputBorder.none,
                    ),
                  ),
                );

                Widget filters = Row(
                  children: [
                    _buildFilterChip('Todas', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Activas', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inactivas', false),
                  ],
                );

                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(child: searchBox),
                      const SizedBox(width: 24),
                      filters,
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      searchBox,
                      const SizedBox(height: 16),
                      SingleChildScrollView(scrollDirection: Axis.horizontal, child: filters),
                    ],
                  );
                }
              }
            ),
            const SizedBox(height: 32),

            // Data Table / List
            _buildRouteItem(context, 'Ruta del Sol - Norte', 'RT-0982', 'Carlos Rodriguez', '24', true, 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=150'),
            _buildRouteItem(context, 'Expreso Central - Sur', 'RT-1143', 'Martha Elena López', '18', true, 'https://images.unsplash.com/photo-1520606775553-61b402ea2688?w=150'),
            _buildRouteItem(context, 'Transversal Occidente', 'RT-0045', 'Juan Camilo Meza', '0', false, 'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=150'),
            _buildRouteItem(context, 'Circuito Educativo A', 'RT-5521', 'Sandra Milena Ortiz', '32', true, 'https://images.unsplash.com/photo-1464219222984-216ebbfdba3e?w=150'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRouteEditScreen()));
        },
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? _primary : const Color(0xFFEBE6F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Colors.grey.shade700)),
    );
  }

  Widget _buildRouteItem(BuildContext context, String name, String code, String driver, String students, bool isActive, String imgUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRouteEditScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          
          List<Widget> children = [
            // Info Column
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover, colorFilter: isActive ? null : const ColorFilter.mode(Colors.grey, BlendMode.saturation)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface)),
                        Text('Cód: $code', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Driver
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: _primary, size: 16),
                  const SizedBox(width: 8),
                  Text(driver, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                ],
              ),
            ),
            // Students
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text('$students Estudiantes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                ],
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isActive ? const Color(0xFFE2DDF4) : const Color(0xFFE5E1EB), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(isActive ? 'ACTIVA' : 'INACTIVA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? _onSurface : Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
            if (isDesktop) const Icon(Icons.more_vert, color: Colors.grey),
          ];

          if (isDesktop) {
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children);
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                children[0], // Info
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [children[1], const SizedBox(height: 8), children[2]],
                    ),
                    children[3] // Status
                  ],
                )
              ],
            );
          }
        }),
      ),
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
            _navItem(context, 'Dashboard', Icons.dashboard, false, const AdminDashboardScreen()),
            _navItem(context, 'Rutas', Icons.directions_bus, true, const AdminRoutesScreen()),
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
