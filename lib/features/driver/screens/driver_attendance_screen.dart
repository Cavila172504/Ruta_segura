import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';
import 'driver_profile_screen.dart';

class DriverAttendanceScreen extends ConsumerStatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  ConsumerState<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends ConsumerState<DriverAttendanceScreen> {
  final Set<String> _presentIds = {};
  bool _isSaving = false;

  // Colores Premium BusGuardian
  final Color _primaryDriver = const Color(0xFF0D4D3A);
  final Color _accentDriver = const Color(0xFFFFD600);
  final Color _surfaceDriver = const Color(0xFFF4F7F6);

  Future<void> _confirmArrivalAtSchool(List<dynamic> students, String unitCode) async {
    setState(() => _isSaving = true);
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      for (var student in students) {
        final studentId = student['id'];
        final parentUid = student['parentUid']; // NECESITAMOS ESTO PARA NOTIFICAR

        // 1. Actualizar estado del estudiante en la empresa
        final studentRef = FirebaseFirestore.instance
            .collection('companies').doc(unitCode).collection('students').doc(studentId);
        batch.update(studentRef, {
          'last_arrival': Timestamp.fromDate(now),
          'attendance_status': _presentIds.contains(studentId) ? 'arrived_at_school' : 'not_picked_up'
        });

        // 2. ENVIAR NOTIFICACIÓN AL PADRE (Si el estudiante está presente)
        if (_presentIds.contains(studentId) && parentUid != null) {
          final notificationRef = FirebaseFirestore.instance
              .collection('users').doc('parents').collection('members').doc(parentUid)
              .collection('notifications').doc();
          
          batch.set(notificationRef, {
            'title': '¡Llegada al Colegio!',
            'message': '${student['studentName']} ha llegado seguro al establecimiento educativo.',
            'timestamp': Timestamp.fromDate(now),
            'type': 'arrival',
            'isRead': false,
          });
        }
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte enviado y padres notificados con éxito.'),
            backgroundColor: Color(0xFF167159),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final unitCode = profileAsync.value?['unitCode'] as String? ?? 'CAD31';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));

    return Scaffold(
      backgroundColor: _surfaceDriver,
      body: studentsAsync.when(
        data: (students) {
          // Inicializar set de presentes si está vacío
          if (_presentIds.isEmpty) {
            for (var s in students) {
               if (s['status'] != 'absent') _presentIds.add(s['id']);
            }
          }

          return Stack(
            children: [
              // Header Gradient
              Positioned(
                top: 0, left: 0, right: 0, height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryDriver, const Color(0xFF167159)]),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // TOP BAR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ASISTENCIA', style: GoogleFonts.publicSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _accentDriver, borderRadius: BorderRadius.circular(12)),
                            child: Text(unitCode, style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w900, color: _primaryDriver)),
                          )
                        ],
                      ),
                    ),

                    // LIST CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Resumen
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                              ),
                              child: Row(
                                children: [
                                  _statCircle((_presentIds.length / (students.isEmpty ? 1 : students.length))),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('CONTADOR PROVISIONAL', style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                                        Text('${_presentIds.length} Estudiantes', style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.w900, color: _primaryDriver)),
                                        Text('listos para ingresar al colegio', style: GoogleFonts.publicSans(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            Text(
                              'LISTA DE RECORRIDO',
                              style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 16),

                            if (students.isEmpty)
                              _emptyState()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final s = students[index];
                                  final id = s['id'];
                                  final isAbsent = s['status'] == 'absent' || s['attendance_status'] == 'absent_today';
                                  final isPresent = _presentIds.contains(id);

                                  return _studentTile(s, isPresent, isAbsent);
                                },
                              ),
                            
                            const SizedBox(height: 40),
                            
                            // Botón de llegada
                            _confirmArrivalButton(students, unitCode),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // NAVBAR
              Positioned(bottom: 0, left: 0, right: 0, child: _navBar(context)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ─── Componentes UI ─────────────────────────────────────────────

  Widget _statCircle(double percent) {
    return SizedBox(
      width: 60, height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: percent, strokeWidth: 8, backgroundColor: _primaryDriver.withOpacity(0.05), color: _primaryDriver),
          Text('${(percent * 100).toInt()}%', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w900, color: _primaryDriver)),
        ],
      ),
    );
  }

  Widget _studentTile(dynamic s, bool isPresent, bool isAbsent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPresent ? _primaryDriver.withOpacity(0.1) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAbsent ? Colors.red.shade50 : _primaryDriver.withOpacity(0.05),
            child: Icon(isAbsent ? Icons.person_off_rounded : Icons.person_rounded, color: isAbsent ? Colors.red : _primaryDriver, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['studentName'] ?? 'Estudiante', style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.w900, color: _primaryDriver)),
                Text(isAbsent ? 'INASISTENCIA REPORTADA' : (isPresent ? 'EN EL BUS' : 'POR RECOGER'), 
                  style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.bold, color: isAbsent ? Colors.red : (isPresent ? const Color(0xFF167159) : Colors.grey))),
              ],
            ),
          ),
          if (!isAbsent)
            Switch(
              value: isPresent, 
              activeColor: _primaryDriver,
              activeTrackColor: _primaryDriver.withOpacity(0.2),
              onChanged: (val) {
                setState(() {
                  if (val) _presentIds.add(s['id']);
                  else _presentIds.remove(s['id']);
                });
              }
            ),
        ],
      ),
    );
  }

  Widget _confirmArrivalButton(List<dynamic> students, String unitCode) {
    return ElevatedButton(
      onPressed: _isSaving ? null : () => _confirmArrivalAtSchool(students, unitCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentDriver,
        foregroundColor: _primaryDriver,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
        shadowColor: _accentDriver.withOpacity(0.3),
      ),
      child: _isSaving 
        ? const CircularProgressIndicator()
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 24),
              const SizedBox(width: 12),
              Text('CONFIRMAR LLEGADA AL COLEGIO', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
    );
  }

  Widget _emptyState() => Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('No hay estudiantes en esta ruta.', style: GoogleFonts.publicSans(color: Colors.grey))));

  Widget _navBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 28, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, 'Dashboard', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()))),
          _navItem(Icons.map_rounded, 'Mapa', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()))),
          _navItem(Icons.how_to_reg_rounded, 'Alumnos', true, () {}),
          _navItem(Icons.person_rounded, 'Perfil', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()))),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _primaryDriver : Colors.grey.shade300, size: 24),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 8, fontWeight: FontWeight.w900, color: active ? _primaryDriver : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
