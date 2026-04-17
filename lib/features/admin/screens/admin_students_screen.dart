import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_routes_screen.dart';
import 'admin_reports_screen.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});
  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String searchQuery = '';

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
              child: const Icon(Icons.school, color: Colors.white, size: 20),
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
            Text('Gestión de Estudiantes', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: _onSurface)),
            Text('Administra la base de datos de estudiantes y sus asignaciones de ruta.', style: GoogleFonts.inter(color: Colors.grey.shade700)),
            const SizedBox(height: 24),

            // Search and Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF6F2FC), borderRadius: BorderRadius.circular(24)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 600;
                  Widget search = Container(
                    decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        icon: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.search, color: Colors.grey)),
                        hintText: 'Buscar estudiante por nombre...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                  Widget filter = Container(
                    decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: 'Filtrar por ruta',
                              items: ['Filtrar por ruta', 'Ruta Norte - 01', 'Ruta Sur - 04'].map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.inter()));
                              }).toList(),
                              onChanged: (_) {},
                              icon: const Icon(Icons.expand_more, color: Colors.grey),
                              isExpanded: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isDesktop) {
                    return Row(
                      children: [
                        Expanded(flex: 2, child: search),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: filter),
                      ],
                    );
                  } else {
                    return Column(
                      children: [search, const SizedBox(height: 12), filter],
                    );
                  }
                }
              ),
            ),
            const SizedBox(height: 24),

            // Students List
            ref.watch(adminAllStudentsProvider).when(
              data: (students) {
                if (students.isEmpty) {
                  return const Center(child: Text('No hay estudiantes registrados o las rutas están vacías.'));
                }
                
                final filtered = students.where((s) {
                  final name = (s['studentName'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay coincidencias en tu búsqueda.'));
                }

                return Column(
                  children: filtered.map((s) {
                    final name = s['studentName'] ?? 'Sin Nombre';
                    final grade = s['grade'] ?? 'Sin Grado';
                    final route = s['unitCode'] ?? 'Sin Unidad';
                    final contact = s['parentEmail'] ?? s['parentName'] ?? 'Sin Contacto';
                    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
                    
                    final companyId = s['companyPath'] ?? s['unitCode'];
                    final studentId = s['id'] ?? s['docId'];
                    final parentId = s['parentId'] ?? '';

                    return _buildStudentCard(
                      initials, const Color(0xFFC5C0FF), const Color(0xFF140067), 
                      name, grade, route, contact,
                      onDelete: () => _confirmDelete(companyId, studentId, parentId, name)
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStudentCard(String initials, Color bgColor, Color textColor, String name, String grade, String route, String contact, {VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        
        var content = [
          _buildInfoColumn('Nombre Completo', name, isTitle: true),
          _buildInfoColumn('Grado', grade),
          _buildInfoColumn('Ruta Asignada', route, isRoute: true),
          _buildInfoColumn('Contacto Acudiente', contact),
        ];

        return Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initials, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: isDesktop 
                ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: content.map((c) => Expanded(child: c)).toList())
                : GridView.count(
                    crossAxisCount: 2, 
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: content,
                  )
            ),
            if (isDesktop) const SizedBox(width: 24),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
              ],
            )
          ],
        );
      }),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isTitle = false, bool isRoute = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        if (isRoute)
          Row(
            children: [
              Icon(Icons.directions_bus, color: _primary, size: 14),
              const SizedBox(width: 4),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _primary)),
            ],
          )
        else
          Text(value, style: isTitle ? GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: _onSurface) : GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, 'Dashboard', Icons.dashboard, false, const AdminDashboardScreen()),
            _navItem(context, 'Rutas', Icons.directions_bus, false, const AdminRoutesScreen()),
            _navItem(context, 'Estudiantes', Icons.school, true, const AdminStudentsScreen()),
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
        decoration: BoxDecoration(color: isActive ? _primaryContainer.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
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

  void _confirmDelete(String? companyId, String? studentId, String parentId, String name) {
    if (companyId == null || studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Faltan datos del estudiante.')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro que deseas eliminar a $name de la plataforma Firebase?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await adminDeleteStudent(companyId, studentId, parentId);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante eliminado con éxito')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }
}
