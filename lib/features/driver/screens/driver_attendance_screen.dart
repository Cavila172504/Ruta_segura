import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/parent_member_utils.dart';
import '../../../core/services/attendance_log_service.dart';
import '../../../core/services/incident_report_service.dart';

// --- COLORES SEGÚN REQUERIMIENTOS ---
const Map<String, Color> _colores = {
  'inasistencia': Color(0xFFD32F2F),
  'fueraDeRango': Color(0xFFE65100),
  'porRecoger': Color(0xFFF57C00),
  'enElBus': Color(0xFF2E7D32),
  'bordeRojo': Color(0xFFFFCDD2),
  'bordeNaranja': Color(0xFFFFB74D),
  'bordeVerde': Color(0xFFA5D6A7),
  'fondoVerde': Color(0xFFF1F8E9),
  'badgeIda': Color(0xFFBBDEFB),
  'badgeRetorno': Color(0xFFFFE0B2),
  'badgeSinInic': Color(0xFFEEEEEE),
  'verdePrimario': Color(0xFF1B5E20),
};

enum EstadoEstudiante { inasistencia, fueraDeRango, porRecoger, enElBus }

class DriverAttendanceScreen extends ConsumerStatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  ConsumerState<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends ConsumerState<DriverAttendanceScreen> {
  final Set<String> _presentIds = {}; // Estudiantes marcados EN EL BUS
  final Set<String> _entregadosIds = {}; // Estudiantes entregados en casa (solo MODO RETORNO)
  final Set<String> _notificadosAproximacionIds = {}; // Estudiantes ya notificados de aproximación
  
  bool _isSaving = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  final Color _primaryDriver = const Color(0xFF0D4D3A);
  final Color _surfaceDriver = const Color(0xFFF4F7F6);

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) setState(() => _currentPosition = position);
      
      // Actualizar ubicación en Firestore para que el padre pueda verlo
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        final unitCode = normalizeUnitCode(profile['unitCode'] as String?);
        final driverId = profile['uid'];
        
        if (unitCode.isNotEmpty && driverId != null) {
          // GPS en live_tracking lo escribe solo driver_map_screen (evita duplicados).
          // Verificar aproximación (600m) en MODO IDA para notificar a los padres
          final routeStatusAsync = ref.read(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId)));
          final routeData = routeStatusAsync.value;
          final bool esModoIda = routeData?['routeType'] == 'to_school';
          final bool recorridoIniciado = routeData?['status'] == 'on_route';

          if (recorridoIniciado && esModoIda) {
            final studentsAsync = ref.read(driverStudentsProvider(unitCode));
            studentsAsync.whenData((students) async {
              for (var s in students) {
                if (s['status'] == 'absent' || s['attendance_status'] == 'absent_today') continue;
                if (_presentIds.contains(s['id'])) continue; 
                if (_notificadosAproximacionIds.contains(s['id'])) continue; 

                final dist = _getDistanceToStudent(s['stopLat'] as double?, s['stopLng'] as double?);
                if (dist <= 600 && s['parentId'] != null) {
                  _notificadosAproximacionIds.add(s['id']);
                  
                  // Estimar tiempo (asumiendo ~20km/h -> 5.5 m/s)
                  double speed = position.speed > 2 ? position.speed : 5.5; 
                  int seconds = (dist / speed).round();
                  int minutes = (seconds / 60).ceil();
                  if (minutes == 0) minutes = 1;

                  await _enviarNotificacionFCM(
                    s['parentId'],
                    '🚌 ¡La unidad está por llegar!',
                    'El bus se encuentra a ${dist.toInt()} metros de distancia. Llegará en aproximadamente $minutes minuto(s).',
                    'approaching'
                  );
                }
              }
            });
          }
        }
      }
    });
  }

  double _getDistanceToStudent(double? lat, double? lng) {
    if (_currentPosition == null || lat == null || lng == null) return 999999;
    return Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
  }

  Future<void> _enviarNotificacionFCM(String parentUid, String titulo, String mensaje, String tipo) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('users').doc('parents').collection('members').doc(parentUid)
          .collection('notifications').doc();
      
      await notificationRef.set({
        'title': titulo,
        'message': mensaje,
        'timestamp': FieldValue.serverTimestamp(),
        'type': tipo,
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error enviando notificación: $e');
    }
  }

  Future<void> _confirmarLlegadaColegio(List<dynamic> students, String unitCode) async {
    setState(() => _isSaving = true);
    try {
      int count = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      final profile = ref.read(userProfileProvider).value;
      final driverId = profile?['uid'] as String?;
      final driverName = profile?['name'] as String? ?? 'Conductor';

      for (var student in students) {
        final studentId = student['id'];
        final parentUid = student['parentId'];
        if (student['status'] == 'absent' || student['attendance_status'] == 'absent_today') continue;

        final studentRef = FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('students').doc(studentId);
        batch.update(studentRef, {
          'last_arrival': Timestamp.fromDate(now),
          'attendance_status': 'arrived_at_school'
        });
        count++;

        if (parentUid != null) {
          final horaStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
          final notificationRef = FirebaseFirestore.instance
              .collection('users').doc('parents').collection('members').doc(parentUid)
              .collection('notifications').doc();
          
          batch.set(notificationRef, {
            'title': '🎓 El bus llegó al colegio • $horaStr',
            'message': 'Tu hijo/a ${student['studentName']} fue entregado con éxito.',
            'timestamp': Timestamp.fromDate(now),
            'type': 'arrival',
            'isRead': false,
          });
          count++;
        }

        if (count >= 390) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();

      for (var student in students) {
        if (student['status'] == 'absent' || student['attendance_status'] == 'absent_today') continue;
        await AttendanceLogService.upsert(
          unitCode: unitCode,
          studentId: student['id'],
          studentName: student['studentName'] ?? '',
          driverId: driverId,
          status: 'arrived_at_school',
          source: 'driver',
          grade: student['grade'],
        );
      }

      if (driverId != null) {
        await IncidentReportService.reportDelayIfNeeded(
          unitCode: unitCode,
          driverId: driverId,
          driverName: driverName,
          arrivalTime: now,
          routeName: students.isNotEmpty ? (students.first['assignedRoute'] as String?) : null,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Confirmación de llegada enviada con éxito.'), backgroundColor: Color(0xFF2E7D32)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmarEntregaCasa(dynamic student, String unitCode) async {
    setState(() => _entregadosIds.add(student['id']));
    try {
      final now = DateTime.now();
      final horaStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final studentRef = FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('students').doc(student['id']);
      await studentRef.update({
        'last_dropoff': Timestamp.fromDate(now),
        'attendance_status': 'dropped_off_at_home'
      });

      final profile = ref.read(userProfileProvider).value;
      await AttendanceLogService.upsert(
        unitCode: unitCode,
        studentId: student['id'],
        studentName: student['studentName'] ?? '',
        driverId: profile?['uid'] as String?,
        status: 'dropped_off_at_home',
        source: 'driver',
        grade: student['grade'],
      );

      if (student['parentId'] != null) {
        await _enviarNotificacionFCM(
          student['parentId'],
          '🏠 ${student['studentName']} fue entregado en casa • $horaStr',
          '¡Que tenga una excelente tarde!',
          'dropoff'
        );
      }
    } catch (e) {
      debugPrint('Error confirmando entrega: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final unitCode = normalizeUnitCode(profileAsync.value?['unitCode'] as String?);
    if (unitCode.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final driverId = profileAsync.value?['uid'] as String? ?? 'UNKNOWN';
    final studentsAsync = ref.watch(driverStudentsProvider(unitCode));
    
    // Obtenemos el estado de la ruta para conocer si inició y qué tipo es (Ida o Retorno)
    final routeStatusAsync = ref.watch(driverRouteStatusProvider((unitCode: unitCode, driverId: driverId)));
    final routeData = routeStatusAsync.value;
    final bool recorridoIniciado = routeData?['status'] == 'on_route';
    final String routeType = routeData?['routeType'] as String? ?? '';
    
    final bool esModoIda = routeType == 'to_school';

    return Scaffold(
      backgroundColor: _surfaceDriver,
      body: studentsAsync.when(
        data: (students) {
          return Stack(
            children: [
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ASISTENCIA', style: GoogleFonts.publicSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () async {
                              await ref.read(authRepositoryProvider).signOut();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // REGLA 3: BADGE INDICADOR DE TIPO DE RECORRIDO
                            Center(child: _recorridoTipoBadge(recorridoIniciado, esModoIda)),
                            const SizedBox(height: 16),

                            // REGLA 5: CONTADOR PROVISIONAL
                            _contadorProvisional(students, recorridoIniciado, esModoIda),
                            const SizedBox(height: 32),
                            
                            Text(
                              'LISTA DE RECORRIDO',
                              style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 16),
                            
                            if (students.isEmpty)
                              Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text('No hay estudiantes asignados hoy', style: GoogleFonts.publicSans(color: Colors.grey))))
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _estudianteCard(students[index], recorridoIniciado, esModoIda, unitCode);
                                },
                              ),
                            
                            const SizedBox(height: 40),
                            // REGLA 2: BOTÓN GLOBAL SOLO MODO IDA
                            _confirmArrivalButton(students, unitCode, esModoIda, recorridoIniciado),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // ==========================================
  // WIDGET: BADGE TIPO DE RECORRIDO
  // ==========================================
  Widget _recorridoTipoBadge(bool iniciado, bool esModoIda) {
    Color bgColor = _colores['badgeSinInic']!;
    Color textColor = Colors.grey.shade700;
    IconData icon = Icons.directions_bus;
    String text = "SIN INICIAR";

    if (iniciado) {
      if (esModoIda) {
        bgColor = _colores['badgeIda']!;
        textColor = Colors.blue.shade900;
        icon = Icons.school;
        text = "IDA AL COLEGIO";
      } else {
        bgColor = _colores['badgeRetorno']!;
        textColor = Colors.orange.shade900;
        icon = Icons.home;
        text = "RETORNO A CASA";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.publicSans(color: textColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET: CONTADOR PROVISIONAL
  // ==========================================
  Widget _contadorProvisional(List<dynamic> students, bool iniciado, bool esModoIda) {
    final validos = students.where((s) => s['status'] != 'absent' && s['attendance_status'] != 'absent_today').toList();
    final enBus = validos.where((s) => _presentIds.contains(s['id'])).length;
    final total = validos.length;
    final porcentaje = total == 0 ? 0.0 : (enBus / total);

    String subtexto = "0 Estudiantes (recorrido no iniciado)";
    if (iniciado) {
      subtexto = esModoIda
          ? "$enBus de $total listos para ingresar al colegio"
          : "$enBus de $total en el bus de regreso";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          SizedBox(
            width: 60, height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: porcentaje,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: _colores['verdePrimario'],
                ),
                Text('${(porcentaje * 100).toInt()}%', style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, color: _colores['verdePrimario'], fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONTADOR PROVISIONAL', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                Text(subtexto, style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET: TARJETA ESTUDIANTE Y REGLAS 1, 2 Y 4
  // ==========================================
  Widget _estudianteCard(dynamic s, bool iniciado, bool esModoIda, String unitCode) {
    final isAbsent = s['status'] == 'absent' || s['attendance_status'] == 'absent_today';
    final isPresent = _presentIds.contains(s['id']);
    final isEntregado = _entregadosIds.contains(s['id']);
    
    final dist = _getDistanceToStudent(s['stopLat'] as double?, s['stopLng'] as double?);
    
    // Regla: 600m en Modo Ida. En Modo Retorno, no bloqueamos por distancia (isFueraDeRango siempre será false)
    final isFueraDeRango = esModoIda ? (dist > 600 && !isPresent) : false; 

    EstadoEstudiante estado = EstadoEstudiante.porRecoger;
    if (isAbsent) estado = EstadoEstudiante.inasistencia;
    else if (isPresent) estado = EstadoEstudiante.enElBus;
    else if (isFueraDeRango) estado = EstadoEstudiante.fueraDeRango;

    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;
    String estadoTexto = "POR RECOGER";
    Color estadoColor = _colores['porRecoger']!;
    
    // REGLA 1: BLOQUEO DEL TOGGLE
    bool toggleHabilitado = iniciado;

    switch (estado) {
      case EstadoEstudiante.inasistencia:
        borderColor = _colores['bordeRojo']!;
        estadoTexto = "INASISTENCIA";
        estadoColor = _colores['inasistencia']!;
        toggleHabilitado = false;
        break;
      case EstadoEstudiante.fueraDeRango:
        borderColor = _colores['bordeNaranja']!;
        estadoTexto = "FUERA DE RANGO";
        estadoColor = _colores['fueraDeRango']!;
        toggleHabilitado = false; // Se bloquea en 600m (Solo aplica a Modo Ida)
        break;
      case EstadoEstudiante.porRecoger:
        borderColor = _colores['bordeNaranja']!;
        estadoTexto = "POR RECOGER";
        estadoColor = _colores['porRecoger']!;
        break;
      case EstadoEstudiante.enElBus:
        borderColor = _colores['bordeVerde']!;
        bgColor = _colores['fondoVerde']!;
        estadoTexto = esModoIda ? "EN EL BUS 🎓" : "EN EL BUS - REGRESO 🏠";
        estadoColor = _colores['enElBus']!;
        break;
    }

    String tooltip = "";
    if (!iniciado) tooltip = "Debes iniciar el recorrido primero";
    else if (estado == EstadoEstudiante.fueraDeRango) tooltip = "El estudiante está fuera del rango de la parada";
    else if (estado == EstadoEstudiante.inasistencia) tooltip = "Estudiante ausente hoy";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: estadoColor.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: estadoColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['studentName'] ?? 'Estudiante',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, fontSize: 16, color: _colores['verdePrimario']),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            estadoTexto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.publicSans(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        // Ocultar distancia si está en bus
                        if (dist < 100000 && !isPresent && !isAbsent) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${dist.toInt()}m',
                            style: GoogleFonts.publicSans(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),
              Tooltip(
                message: tooltip,
                child: Switch(
                  value: isPresent,
                  activeColor: _colores['enElBus'],
                  onChanged: toggleHabilitado ? (val) async {
                    setState(() {
                      if (val) _presentIds.add(s['id']);
                      else _presentIds.remove(s['id']);
                    });

                    try {
                      // ── SINCRONIZACIÓN EN TIEMPO REAL CON LA BASE DE DATOS ──
                      final studentRef = FirebaseFirestore.instance.collection('companies').doc(unitCode).collection('students').doc(s['id']);
                      final newStatus = val ? 'in_bus' : 'pending';
                      await studentRef.update({
                        'attendance_status': newStatus
                      });
                      if (val) {
                        final profile = ref.read(userProfileProvider).value;
                        await AttendanceLogService.upsert(
                          unitCode: unitCode,
                          studentId: s['id'],
                          studentName: s['studentName'] ?? '',
                          driverId: profile?['uid'] as String?,
                          status: 'in_bus',
                          source: 'driver',
                          grade: s['grade'],
                        );
                      }
                    } catch (e) {
                      debugPrint('Error actualizando estado en Firestore: $e');
                    }

                    if (val && s['parentId'] != null) {
                      final horaStr = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
                      if (esModoIda) {
                        await _enviarNotificacionFCM(
                          s['parentId'],
                          '🟢 ${s['studentName']} subió al bus • $horaStr',
                          'Llegada estimada al colegio: 07:30 AM',
                          'boarded'
                        );
                      } else {
                        await _enviarNotificacionFCM(
                          s['parentId'],
                          '🏫 ${s['studentName']} está en la unidad escolar y de regreso a casa • $horaStr',
                          'Llegada estimada a casa: 14:45 PM',
                          'boarded'
                        );
                      }
                    }
                  } : null,
                ),
              )
            ],
          ),
          
          // REGLA 2: BOTÓN CONFIRMAR ENTREGA CASA (Modo Retorno)
          if (!esModoIda && isPresent)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: isEntregado ? null : () => _confirmarEntregaCasa(s, unitCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEntregado ? 'ENTREGADO EN CASA ✅' : 'CONFIRMAR ENTREGA EN CASA',
                  style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            )
        ],
      ),
    );
  }

  // ==========================================
  // BOTÓN GLOBAL LLEGADA (Modo Ida)
  // ==========================================
  Widget _confirmArrivalButton(List<dynamic> students, String unitCode, bool esModoIda, bool iniciado) {
    if (!iniciado || !esModoIda) return const SizedBox.shrink();
    
    final validos = students.where((s) => s['status'] != 'absent' && s['attendance_status'] != 'absent_today');
    final puedeConfirmar = validos.isNotEmpty && validos.every((s) => _presentIds.contains(s['id']));

    return ElevatedButton(
      onPressed: (!puedeConfirmar || _isSaving) ? null : () => _confirmarLlegadaColegio(students, unitCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: _colores['verdePrimario'],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: puedeConfirmar ? 10 : 0, 
      ),
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_rounded),
                const SizedBox(width: 12),
                Text('CONFIRMAR LLEGADA AL COLEGIO', style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              ],
            ),
    );
  }
}
