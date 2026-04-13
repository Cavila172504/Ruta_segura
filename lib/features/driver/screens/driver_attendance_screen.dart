import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/screens/login_screen.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';
import 'driver_profile_screen.dart';

class DriverAttendanceScreen extends ConsumerStatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  ConsumerState<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends ConsumerState<DriverAttendanceScreen> {
  final Map<String, bool> _attendanceMap = {};

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final unitCode = profileAsync.value?['unitCode'] as String? ?? 'UNIDAD-GENERICA';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF044837),
        elevation: 0,
        titleSpacing: 24,
        title: profileAsync.when(
          data: (profile) => Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    profile?['name'] != null ? profile!['name'].toString()[0].toUpperCase() : 'C',
                    style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF044837)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'RUTASEGURA',
                style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('ERROR'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryContainer),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
        automaticallyImplyLeading: false,
      ),
      body: studentsAsync.when(
        data: (students) {
          final total = students.length;
          final presents = students.where((s) => _attendanceMap[s['id']] ?? true).length;
          final percentage = total > 0 ? presents / total : 0.0;

          return Stack(
            children: [
              Positioned.fill(
                bottom: 80,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress Hero Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: const Border(bottom: BorderSide(color: AppColors.primaryContainer, width: 4)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ESTADO ACTUAL', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    Text('$presents de $total', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.onSurface, height: 1)),
                                    const SizedBox(height: 4),
                                    Text('estudiantes presentes', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                                  ],
                                ),
                                Text('${(percentage * 100).toInt()}%', style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary, fontStyle: FontStyle.italic)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 16,
                              decoration: BoxDecoration(color: const Color(0xFFA0F3D4), borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.5), blurRadius: 12)]
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('LISTA DE ESTUDIANTES', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.onSurfaceVariant)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFA0F3D4), borderRadius: BorderRadius.circular(12)),
                            child: Text('Ruta $unitCode', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF167159))),
                          )
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No hay estudiantes registrados en esta unidad.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.publicSans(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final id = student['id'] as String;
                            final status = student['status'] as String? ?? 'active';
                            final isAbsent = status == 'absent';
                            
                            return _buildStudentItem(
                              id: id,
                              name: student['studentName'] as String,
                              desc: isAbsent ? 'ESTADO: AUSENTE' : 'ESTADO: ACTIVO',
                              isPresent: isAbsent ? false : (_attendanceMap[id] ?? true),
                              forcedAbsent: isAbsent,
                            );
                          },
                        ),

                      const SizedBox(height: 48),

                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sincronizando asistencia con la nube...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: const Color(0xFF221B00),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          side: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        icon: const Icon(Icons.how_to_reg, size: 24),
                        label: Text('GUARDAR ASISTENCIA', style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ÚLTIMA SINCRONIZACIÓN: HOY',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: AppColors.onSurfaceVariant.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(icon: Icons.route, label: 'Ruta', isActive: false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()))),
                      _navItem(icon: Icons.map, label: 'Mapa', isActive: false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()))),
                      _navItem(icon: Icons.assignment_turned_in, label: 'Asistencia', isActive: true, onTap: () {}),
                      _navItem(icon: Icons.person, label: 'Perfil', isActive: false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()))),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStudentItem({
    required String id,
    required String name,
    required String desc,
    required bool isPresent,
    bool forcedAbsent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: forcedAbsent ? AppColors.error : (isPresent ? AppColors.primary : Colors.transparent), 
            width: 4
          )
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: forcedAbsent ? const Color(0xFFFFDAD6).withOpacity(0.3) : AppColors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              forcedAbsent ? Icons.person_off : Icons.person, 
              color: forcedAbsent ? AppColors.error : AppColors.primary
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: GoogleFonts.publicSans(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: forcedAbsent ? AppColors.error : AppColors.onSurface
                  )
                ),
                Text(
                  desc, 
                  style: GoogleFonts.publicSans(
                    fontSize: 10, 
                    fontWeight: FontWeight.w600, 
                    color: forcedAbsent ? AppColors.error : AppColors.onSurfaceVariant
                  )
                )
              ],
            ),
          ),
          if (!forcedAbsent)
            GestureDetector(
              onTap: () => setState(() => _attendanceMap[id] = !isPresent),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56, height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: isPresent ? AppColors.primaryContainer : const Color(0xFFE8E8E8)),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isPresent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: isPresent ? AppColors.primary : const Color(0xFFD0C6AB))),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'REPORTADO',
                style: GoogleFonts.publicSans(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ),
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
            decoration: BoxDecoration(color: isActive ? AppColors.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: isActive ? const Color(0xFF044837) : Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: isActive ? const Color(0xFF044837) : Colors.grey.shade500)),
        ],
      ),
    );
  }
}
