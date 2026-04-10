import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_screen.dart';
import 'admin_routes_screen.dart';
import 'admin_students_screen.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  final Color _primary = const Color(0xFF3B309E);
  final Color _primaryContainer = const Color(0xFF534AB7);
  final Color _surface = const Color(0xFFFCF8FF);
  final Color _onSurface = const Color(0xFF1C1B22);
  final Color _surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color _error = const Color(0xFFBA1A1A);

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
              child: const Icon(Icons.analytics, color: Colors.white, size: 20),
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
            Text('Informes y Reportes', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: _onSurface)),
            Text('Análisis detallado de la operación logística y seguridad escolar.', style: GoogleFonts.inter(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),

            // Controls Bento Grid
            LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 800;
                Widget filters = _buildFilterPanel();
                Widget downloads = _buildDownloadPanel();

                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(flex: 8, child: filters),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: downloads),
                    ],
                  );
                } else {
                  return Column(
                    children: [filters, const SizedBox(height: 24), downloads],
                  );
                }
              }
            ),
            const SizedBox(height: 32),

            // Summary Stats
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatCard('Viajes totales', '1,284', '+12% vs mes anterior', Icons.route, Icons.trending_up, Colors.green),
                    _buildStatCard('Estudiantes transportados', '45,102', '+5.4% vs mes anterior', Icons.groups, Icons.trending_up, Colors.green),
                    _buildStatCard('Incidentes reportados', '12', '-2 vs mes anterior', Icons.report_problem, Icons.priority_high, _error, isError: true),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),

            // Preview Table
            Container(
              decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.withOpacity(0.2))),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vista Previa de Actividad', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: const Icon(Icons.chevron_left, size: 20)),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: const Icon(Icons.chevron_right, size: 20)),
                          ],
                        )
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.5),
                      dataTextStyle: GoogleFonts.inter(fontSize: 14, color: _onSurface),
                      columns: const [
                        DataColumn(label: Text('FECHA')),
                        DataColumn(label: Text('RUTA')),
                        DataColumn(label: Text('CONDUCTOR')),
                        DataColumn(label: Text('ESTUDIANTES')),
                        DataColumn(label: Text('INCIDENTES')),
                      ],
                      rows: [
                        _buildDataRow('24 Nov, 2023', 'Ruta Norte 01', 'Ricardo Mendoza', '42/45', 'Ninguno', false),
                        _buildDataRow('23 Nov, 2023', 'Ruta Sur 04', 'Ana Lozano', '38/40', '1 Reportado', true),
                        _buildDataRow('23 Nov, 2023', 'Ruta Oriente 02', 'Carlos Paez', '45/45', 'Ninguno', false),
                        _buildDataRow('22 Nov, 2023', 'Ruta Norte 01', 'Ricardo Mendoza', '40/45', 'Ninguno', false),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFF6F2FC),
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Text('Ver todos los registros'),
                      label: const Icon(Icons.arrow_forward, size: 16),
                      style: TextButton.styleFrom(foregroundColor: _primary, textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF6F2FC), borderRadius: BorderRadius.circular(32)),
      child: LayoutBuilder(builder: (context, constraints) {
        var content = [
          _buildFilterCol('Desde', '2023-11-01', isDate: true),
          _buildFilterCol('Hasta', '2023-11-30', isDate: true),
          _buildFilterCol('Filtrar por ruta', 'Todas las rutas', isDropdown: true),
          Padding(
            padding: EdgeInsets.only(top: constraints.maxWidth > 600 ? 24.0 : 0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt, size: 18),
              label: Text('Aplicar Filtros', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          )
        ];

        if (constraints.maxWidth > 600) {
          return Row(crossAxisAlignment: CrossAxisAlignment.end, children: content.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList());
        } else {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
        }
      }),
    );
  }

  Widget _buildFilterCol(String label, String value, {bool isDate = false, bool isDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _primary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFFEBE6F0), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
          child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _onSurface)),
        ),
      ],
    );
  }

  Widget _buildDownloadPanel() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.red.shade100)),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.picture_as_pdf, color: Colors.red)),
                const SizedBox(height: 8),
                Text('Descargar PDF', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _onSurface)),
                Text('2.4 MB', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.green.shade100)),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: const Icon(Icons.table_view, color: Colors.green)),
                const SizedBox(height: 8),
                Text('Descargar Excel', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _onSurface)),
                Text('1.8 MB', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData bgIcon, IconData subIcon, Color subColor, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Icon(bgIcon, size: 100, color: Colors.grey.shade100)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w800, color: isError ? _error : _primary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(subIcon, size: 14, color: subColor),
                  const SizedBox(width: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: subColor)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  DataRow _buildDataRow(String date, String route, String driver, String students, String incidents, bool hasIncident) {
    return DataRow(
      cells: [
        DataCell(Text(date, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(route, style: TextStyle(fontWeight: FontWeight.bold, color: _primary))),
        DataCell(Text(driver)),
        DataCell(Text(students, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: hasIncident ? const Color(0xFFFFDAD6) : const Color(0xFFEBE6F0), borderRadius: BorderRadius.circular(12)),
            child: Text(incidents.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: hasIncident ? const Color(0xFF93000A) : const Color(0xFF454653))),
          )
        ),
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
            _navItem(context, 'Dashboard', Icons.dashboard, false, const AdminDashboardScreen()),
            _navItem(context, 'Rutas', Icons.directions_bus, false, const AdminRoutesScreen()),
            _navItem(context, 'Estudiantes', Icons.school, false, const AdminStudentsScreen()),
            _navItem(context, 'Reportes', Icons.analytics, true, const AdminReportsScreen()),
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
