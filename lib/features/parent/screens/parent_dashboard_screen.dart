import 'package:flutter/material.dart';
import '../../../core/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import 'parent_map_screen.dart';
import 'parent_notifications_screen.dart';
import 'add_student_screen.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  // Colores del tema Parent (Blue Theme)
  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);
  final Color _onSurface = const Color(0xFF191c1d);
  final Color _onSurfaceVariant = const Color(0xFF424751);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).value;
    
    // Lógica robusta para el nombre
    String rawName = 'Padre';
    if (userProfileAsync.value != null && userProfileAsync.value!['name'] != null) {
      rawName = userProfileAsync.value!['name'].toString();
    } else if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
      rawName = authUser.displayName!;
    }
    
    final firstName = rawName.split(' ').first;
    
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }
    
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 140, left: 24, right: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  Text(
                    '$greeting, $firstName',
                    style: GoogleFonts.publicSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _onSurface,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sección Mis Estudiantes (dinámica desde Firestore)
                  Consumer(
                    builder: (context, ref, _) {
                      final studentsAsync = ref.watch(parentStudentsProvider);

                      return studentsAsync.when(
                        loading: () => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (students) {
                          if (students.isEmpty) {
                            // Estado vacío: invitar a agregar estudiante
                            return Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryContainer.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFd9e4ee),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.child_care, color: _primary, size: 32),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sin estudiantes registrados',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Agrega a tu hijo para comenzar el seguimiento en tiempo real',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      color: _onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const AddStudentScreen())),
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      'AÑADIR ESTUDIANTE',
                                      style: GoogleFonts.publicSans(fontWeight: FontWeight.w800),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryContainer,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Listar cada estudiante
                          return Column(
                            children: students.map((student) {
                              final name = student['studentName'] as String? ?? 'Estudiante';
                              final unitCode = student['unitCode'] as String? ?? '--';
                              final initial = name[0].toUpperCase();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryContainer.withValues(alpha: 0.07),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 56, height: 56,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFd9e4ee),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        initial,
                                                        style: GoogleFonts.publicSans(
                                                          fontSize: 24,
                                                          fontWeight: FontWeight.w900,
                                                          color: _primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: GoogleFonts.publicSans(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w800,
                                                          color: _onSurface,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Unidad: $unitCode',
                                                        style: GoogleFonts.publicSans(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: _onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1a6b3a),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'ACTIVO',
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
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Container(
                                                width: 36, height: 36,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFe7e8e9),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(Icons.route, color: _primary, size: 18),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('UNIDAD ESCOLAR',
                                                        style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _onSurfaceVariant)),
                                                    Text(unitCode,
                                                        style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.bold, color: _onSurface),
                                                        overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      color: const Color(0xFFd4e3ff),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.pushReplacement(context,
                                            MaterialPageRoute(builder: (_) => const ParentMapScreen())),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryContainer,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 2,
                                        ),
                                        icon: const Icon(Icons.map, size: 18),
                                        label: Text('VER EN MAPA',
                                            style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),

                  
                  // Quick Actions (Absence Reporting Only)
                  Text(
                    'REPORTE DE ASISTENCIA',
                    style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showAbsenceConfirmation(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDE7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: Color(0xFFFFDAD6), shape: BoxShape.circle),
                            child: const Icon(Icons.no_accounts, color: Color(0xFF410002), size: 28),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mi hijo no asistirá hoy',
                                  style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF410002)),
                                ),
                                Text(
                                  'Notificar que el bus no pase hoy',
                                  style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF410002).withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF410002)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Espacio final para que no lo cubra el nav
                ],
              ),
            ),
          ),

          // Top App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRect(
              child: Container(
                color: Colors.white.withValues(alpha: 0.85),
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
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.grey.shade500),
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
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
                  boxShadow: [
                    BoxShadow(color: _primaryContainer.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context, icon: Icons.home, label: 'Inicio', isActive: true, target: const ParentDashboardScreen()),
                    _navItem(context, icon: Icons.map, label: 'Mapa', isActive: false, target: const ParentMapScreen()),
                    _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: false, target: const ParentNotificationsScreen()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          onPressed: () {
            _showAddStudentWarning(context);
          },
          icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
          label: Text('Agregar Alumno', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _primaryContainer,
          elevation: 4,
        ),
      ),
    );
  }

  void _showAddStudentWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text('Atención', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Para registrar un nuevo alumno es necesario ingresar el código de la unidad educativa o del transporte asignado a la que quiere ingresar.\n\n¿Desea continuar?',
            style: GoogleFonts.publicSans(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: GoogleFonts.publicSans(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Ocultar el diálogo
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen())); // Ir a la pantalla
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Aceptar', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  void _showAbsenceConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            '¿Confirmar inasistencia?',
            style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, color: const Color(0xFF410002)),
          ),
          content: Text(
            'Al confirmar, el conductor recibirá una alerta automática y NO se detendrá en su ubicación el día de hoy.\n\nEsto garantiza la seguridad y fluidez de la ruta sin distracciones.',
            style: GoogleFonts.publicSans(fontSize: 15, color: const Color(0xFF410002)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('CANCELAR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí iría la lógica para enviar a Firestore
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inasistencia reportada con éxito.'),
                    backgroundColor: Colors.black87,
                  )
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('CONFIRMAR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget target}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.publicSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: isActive ? _primaryContainer : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }
}
