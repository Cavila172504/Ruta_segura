import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../../core/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/parent_provider.dart';
import 'parent_schools_screen.dart';
import 'parent_nav_shell.dart';
import 'add_student_screen.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/parent_member_utils.dart';
import '../../../core/services/attendance_log_service.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => widget.embeddedInShell;

  // Colores del tema Parent (Blue Theme)
  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);
  final Color _onSurface = const Color(0xFF191c1d);
  final Color _onSurfaceVariant = const Color(0xFF424751);

  // Bandera para evitar doble navegación
  bool _hasNavigatedToMap = false;
  bool _didBootstrap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_didBootstrap) return;
      _didBootstrap = true;
      await subscribeParentToAllLinkedBuses(ref);
      final linked = await ref.read(linkedUnitCodesProvider.future);
      if (!mounted) return;
      if (linked.isEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ParentSchoolsScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Iniciar el monitoreo de cercanía y eventos del bus
    ref.watch(proximityMonitoringProvider);
    ref.watch(remoteNotificationsListenerProvider);

    // Auto-navegación al mapa solo cuando no usamos el shell con pestañas.
    if (!widget.embeddedInShell) {
      ref.listen<AsyncValue<String>>(busStatusProvider, (previous, next) {
        final prevStatus = previous?.value ?? 'idle';
        final newStatus = next.value ?? 'idle';
        if (newStatus == 'on_route' && prevStatus != 'on_route' && !_hasNavigatedToMap && mounted) {
          _hasNavigatedToMap = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ParentShellScreen(initialIndex: 1)),
          );
        }
        if (newStatus != 'on_route') {
          _hasNavigatedToMap = false;
        }
      });
    }

    // Auto-suscribir al topic FCM del bus cuando carguen los estudiantes.
    // Así el padre recibe push incluso si la app estuvo cerrada un tiempo.
    ref.listen(linkedUnitCodesProvider, (_, next) {
      next.whenData((codes) {
        for (final code in codes) {
          NotificationService().subscribeToBus(code);
        }
      });
    });
    
    final userProfileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).value;
    
    // Lógica mejorada para el nombre: Priorizar nombre real del usuario autenticado
    String rawName = 'Padre';
    if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
      rawName = authUser.displayName!;
    } else if (userProfileAsync.value != null && userProfileAsync.value!['name'] != null) {
      rawName = userProfileAsync.value!['name'].toString();
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

    final scaffoldWidget = Scaffold(
        backgroundColor: _surface,
        body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Scrollable Content
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: widget.embeddedInShell ? 24 : 80,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 140, left: 24, right: 24, bottom: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 220),
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
                  const SizedBox(height: 16),
                  _SchoolSelectorBar(
                    onManageSchools: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ParentSchoolsScreen(selectOnly: true)),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

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
                                    onPressed: _openAddStudent,
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

                          // Listado de estudiantes (Hermanos)
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'ESTUDIANTES VINCULADOS',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: _onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              ...students.map((student) {
                                final name = student['studentName'] as String? ?? 'Estudiante';
                                final unitCode = student['unitCode'] as String? ?? 'CADE';
                                final status = student['status'] as String? ?? 'pending';
                                final grade = student['grade'] as String? ?? '--';
                                final serviceType = student['serviceType'] as String? ?? '--';
                                final studentId = student['studentId'] ?? student['id'];
                                final isActive = status == 'active';
                                final initial = name[0].toUpperCase();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Avatar con Inicial
                                            Container(
                                              width: 50, height: 50,
                                              decoration: BoxDecoration(
                                                color: isActive ? _primaryContainer.withValues(alpha: 0.1) : Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  initial,
                                                  style: GoogleFonts.publicSans(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w900,
                                                    color: isActive ? _primary : Colors.amber.shade800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Info del Estudiante
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.publicSans(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: _onSurface,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${unitCode.startsWith('CAD') ? 'CADE' : unitCode} • $grade',
                                                    style: GoogleFonts.publicSans(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: _onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Servicio: $serviceType',
                                                    style: GoogleFonts.publicSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isActive ? Colors.green.shade700 : Colors.amber.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Footer con Estado y Botón de Mapa
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isActive ? _primaryContainer.withValues(alpha: 0.05) : Colors.grey.shade50,
                                          border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                        ),
                                          child: Wrap(
                                            alignment: WrapAlignment.spaceBetween,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              // Badge de Estado
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: isActive ? const Color(0xFF1a6b3a) : const Color(0xFFb78b01),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isActive ? 'ACTIVO' : 'EN ESPERA',
                                                  style: GoogleFonts.publicSans(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              // Botones de acción
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isActive)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 8),
                                                      child: SizedBox(
                                                        height: 36,
                                                        child: student['attendance_status'] == 'absent_today'
                                                          ? ElevatedButton(
                                                              onPressed: () => _toggleAbsence(context, ref, name, studentId, unitCode, false),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.green.shade600,
                                                                foregroundColor: Colors.white,
                                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                              ),
                                                              child: Text(
                                                                'SÍ ASISTE (ANULAR)',
                                                                style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900),
                                                              ),
                                                            )
                                                          : OutlinedButton(
                                                              onPressed: () => _toggleAbsence(context, ref, name, studentId, unitCode, true),
                                                              style: OutlinedButton.styleFrom(
                                                                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                                                                foregroundColor: Colors.redAccent,
                                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                              ),
                                                              child: Text(
                                                                'NO ASISTE HOY',
                                                                style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.w900),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    height: 36,
                                                    child: ElevatedButton.icon(
                                                      onPressed: isActive
                                                          ? () {
                                                              ref
                                                                  .read(parentShellTabIndexProvider
                                                                      .notifier)
                                                                  .selectTab(1);
                                                            }
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: _primary,
                                                        foregroundColor: Colors.white,
                                                        elevation: 0,
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                      icon: const Icon(Icons.location_on_rounded, size: 14),
                                                      label: Text(
                                                        isActive ? 'VER MAPA' : 'BLOQUEADO',
                                                        style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                      ),
                                      // Mensaje de inasistencia persistente
                                      if (isActive && student['attendance_status'] == 'absent_today')
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          color: Colors.red.shade50,
                                          child: Center(
                                            child: Text(
                                              '📢 REPORTE: NO ASISTE A CLASES HOY',
                                              style: GoogleFonts.publicSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.red.shade700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  
                  // Soporte y Contacto (Reemplazo del reporte redundante)
                  Text(
                    'SOPORTE Y AYUDA',
                    style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.headset_mic_rounded, color: _primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Necesitas ayuda?',
                                style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface),
                              ),
                              Text(
                                'Contactar con administración',
                                style: GoogleFonts.publicSans(fontSize: 12, color: _onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showSupportDialog(context, ref),
                          style: TextButton.styleFrom(
                            foregroundColor: _primary,
                            textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                          child: const Text('CONTACTAR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Espacio para no chocar con el FAB y barra nav

                      ],
                    ),
                  ),
                ),
              ),
              // Resto de elementos del Stack...

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
                          'RutaSegura',
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

          if (!widget.embeddedInShell)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: _primaryContainer.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8))
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(context, icon: Icons.home_rounded, label: 'Inicio', isActive: true, target: const ParentShellScreen()),
                      _navItem(context, icon: Icons.map_rounded, label: 'Mapa', isActive: false, target: const ParentShellScreen(initialIndex: 1)),
                      _navItem(context, icon: Icons.notifications_rounded, label: 'Notificaciones', isActive: false, target: const ParentShellScreen(initialIndex: 2)),
                    ],
                  ),
                ),
              ),
            )
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.embeddedInShell ? 8 : 60),
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

    if (widget.embeddedInShell) return scaffoldWidget;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Salir de la App', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            content: Text('¿Deseas cerrar la aplicación RutaSegura?', style: GoogleFonts.publicSans()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('CANCELAR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SALIR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: scaffoldWidget,
    );
  }

  void _openAddStudent() async {
    final active = await ref.read(activeUnitCodeProvider.future);
    if (!mounted) return;
    if (active == null || active.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ParentSchoolsScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddStudentScreen(fixedUnitCode: active)),
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
              Expanded(child: Text('Atención', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(
            'Registrarás un alumno en el colegio activo. El código ya viene precargado.\n\n¿Desea continuar?',
            style: GoogleFonts.publicSans(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: GoogleFonts.publicSans(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openAddStudent();
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


  Future<void> _setStudentAttendance(
    WidgetRef ref,
    String studentId,
    String unitCode,
    String attendanceStatus,
  ) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('Sesión no válida');

    final id = studentId.trim();
    final code = unitCode.trim().toUpperCase();
    if (id.isEmpty || code.isEmpty) {
      throw Exception('Datos del estudiante incompletos.');
    }

    final payload = <String, dynamic>{
      'attendance_status': attendanceStatus,
      'attendance_updated_at': FieldValue.serverTimestamp(),
    };

    await withNetworkTimeout(
      FirebaseFirestore.instance
          .collection('companies')
          .doc(code)
          .collection('students')
          .doc(id)
          .set(payload, SetOptions(merge: true)),
    );

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(code)
          .collection('students')
          .doc(id)
          .get();
      final data = snap.data();
      if (data != null) {
        await AttendanceLogService.upsert(
          unitCode: code,
          studentId: id,
          studentName: (data['studentName'] ?? '') as String,
          driverId: data['driverId'] as String?,
          status: attendanceStatus,
          source: 'parent',
          grade: data['grade'] as String?,
        );
      }
    } catch (_) {}

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc('parents')
          .collection('members')
          .doc(user.uid)
          .collection('students')
          .doc(id)
          .set(payload, SetOptions(merge: true));
    } catch (_) {}
  }

  void _showAbsenceConfirmation(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(parentStudentsProvider);
    
    if (!studentsAsync.hasValue || studentsAsync.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes estudiantes vinculados para reportar.'))
      );
      return;
    }

    final students = studentsAsync.value!;
    Map<String, bool> selection = {
      for (var s in students) (s['studentId'] ?? s['id']): false
    };

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPORTE DE ASISTENCIA',
                    style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.red.shade800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Quién no asistirá hoy?',
                    style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, color: const Color(0xFF410002), fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: students.map((student) {
                    final id = student['studentId'] ?? student['id'];
                    final name = student['studentName'] ?? 'Estudiante';
                    return CheckboxListTile(
                      value: selection[id],
                      activeColor: Colors.red.shade700,
                      title: Text(name, style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(student['grade'] ?? '', style: GoogleFonts.publicSans(fontSize: 11)),
                      onChanged: (val) {
                        setState(() => selection[id] = val!);
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('CANCELAR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: !selection.values.contains(true) ? null : () async {
                    try {
                      for (final student in students) {
                        final id = (student['studentId'] ?? student['id'])?.toString();
                        if (id == null || id.isEmpty) continue;
                        if (selection[id] != true) continue;
                        final unitCode =
                            (student['unitCode'] as String?) ?? 'CADE';
                        await _setStudentAttendance(
                          ref,
                          id,
                          unitCode,
                          'absent_today',
                        );
                      }

                      ref.invalidate(parentStudentsProvider);

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificación enviada al conductor.'),
                            backgroundColor: Colors.black87,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error al enviar el reporte: ${friendlyNetworkError(e)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('NOTIFICAR FALTA', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _primary : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.publicSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isActive ? _primary : Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteStudentConfirmation(BuildContext context, WidgetRef ref, String name, String studentId, String unitCode) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Eliminar Estudiante', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(
            '¿Estás SEGURO de que deseas eliminar a $name?\n\nEsta acción es permanente y ya no podrás rastrear su ruta.',
            style: GoogleFonts.publicSans(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('CANCELAR', style: GoogleFonts.publicSans(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final authRepo = ref.read(authRepositoryProvider);
                  final uid = await authRepo.getCurrentUserId();
                  
                  if (uid != null) {
                    final batch = FirebaseFirestore.instance.batch();
                    
                    // 1. Borrar de la colección de la compañía
                    final compStudentRef = FirebaseFirestore.instance
                        .collection('companies')
                        .doc(unitCode)
                        .collection('students')
                        .doc(studentId);
                    batch.delete(compStudentRef);
                    
                    // 2. Borrar del perfil del padre
                    final parentQuery = await FirebaseFirestore.instance
                        .collection('users')
                        .doc('parents')
                        .collection('members')
                        .where('uid', isEqualTo: uid)
                        .limit(1)
                        .get();
                        
                    if (parentQuery.docs.isNotEmpty) {
                      final parentDocRef = parentQuery.docs.first.reference;
                      batch.delete(parentDocRef.collection('students').doc(studentId));
                    }
                    
                    await batch.commit();
                  }

                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name ha sido eliminado.'), backgroundColor: Colors.redAccent)
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al eliminar estudiante.'), backgroundColor: Colors.red)
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ELIMINAR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _toggleAbsence(BuildContext context, WidgetRef ref, String name, String studentId, String unitCode, bool setAsAbsent) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            setAsAbsent ? 'Confirmar inasistencia' : 'Confirmar asistencia',
            style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, color: const Color(0xFF410002)),
          ),
          content: Text(
            setAsAbsent 
              ? '¿Confirmas que $name NO asistirá a clases hoy?\n\nSe notificará al conductor de inmediato.' 
              : '¿Has cambiado de opinión? ¿Confirmas que $name SÍ asistirá a clases hoy?',
            style: GoogleFonts.publicSans(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('CANCELAR', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _setStudentAttendance(
                    ref,
                    studentId.toString(),
                    unitCode,
                    setAsAbsent ? 'absent_today' : 'present',
                  );
                  ref.invalidate(parentStudentsProvider);

                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(setAsAbsent ? 'Reportado: $name no asiste hoy.' : 'Reporte anulado: $name sí asiste.'),
                        backgroundColor: setAsAbsent ? Colors.redAccent : Colors.green.shade600,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${friendlyNetworkError(e)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: setAsAbsent ? Colors.redAccent : Colors.green.shade600,
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

  void _showSupportDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSubmitting = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.chat, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Contactar Soporte', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold))),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuéntanos brevemente qué sucede para poder ayudarte mejor:',
                      style: GoogleFonts.publicSans(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje aquí...',
                        hintStyle: GoogleFonts.publicSans(fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text('CANCELAR', style: GoogleFonts.publicSans(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final message = messageController.text.trim();
                    if (message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, escribe un mensaje.')));
                      return;
                    }

                    setState(() => isSubmitting = true);

                    try {
                      final authUser = ref.read(authStateProvider).value;
                      final uid = authUser?.uid;
                      if (uid == null) throw Exception('Sesión no válida');

                      String unitCode = normalizeUnitCode(
                        await ref.read(activeUnitCodeProvider.future),
                      );
                      if (unitCode.isEmpty) {
                        final memberData = await readParentMemberData(uid);
                        unitCode = normalizeUnitCode(
                          resolveActiveUnitCode(memberData),
                        );
                      }
                      if (unitCode.isEmpty) {
                        throw Exception(
                          'Vincula tu colegio antes de contactar soporte.',
                        );
                      }

                      final parentName = authUser?.displayName?.trim().isNotEmpty == true
                          ? authUser!.displayName!.trim()
                          : (authUser?.email ?? 'Padre');

                      await withNetworkTimeout(
                        FirebaseFirestore.instance
                            .collection('companies')
                            .doc(unitCode)
                            .collection('support_tickets')
                            .add({
                          'parentId': uid,
                          'parentName': parentName,
                          'parentEmail': authUser?.email ?? '',
                          'unitCode': unitCode,
                          'message': message,
                          'timestamp': FieldValue.serverTimestamp(),
                          'status': 'open',
                          'type': 'support_request',
                        }),
                      );

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc('parents')
                            .collection('members')
                            .doc(uid)
                            .collection('notifications')
                            .add({
                          'title': 'Soporte enviado',
                          'message':
                              'Tu mensaje ha sido recibido por el administrador.',
                          'type': 'support',
                          'timestamp': FieldValue.serverTimestamp(),
                          'isRead': false,
                        });
                      } catch (e) {
                        debugPrint('Ignorando error de notificación local: $e');
                      }

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mensaje enviado a administración. Te contactaremos pronto.',
                            ),
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error al enviar: ${friendlyNetworkError(e)}',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('ENVIAR A ADMIN', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class _SchoolSelectorBar extends ConsumerWidget {
  const _SchoolSelectorBar({required this.onManageSchools});

  final VoidCallback onManageSchools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeUnitCodeProvider);
    final linkedAsync = ref.watch(linkedUnitCodesProvider);

    return linkedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (codes) {
        if (codes.isEmpty) {
          return OutlinedButton.icon(
            onPressed: onManageSchools,
            icon: const Icon(Icons.school),
            label: const Text('Vincular primer colegio'),
          );
        }

        return activeAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (active) {
            final current = active ?? codes.first;
            return FutureBuilder<Map<String, dynamic>?>(
              future: ref.read(companyByUnitProvider(current).future),
              builder: (context, snap) {
                final schoolName = snap.data?['name'] as String? ?? current;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF004782).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Color(0xFF004782)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Colegio activo',
                              style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              '$schoolName ($current)',
                              style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onManageSchools,
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
