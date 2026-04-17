import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';

class DriverAttendanceScreen extends ConsumerStatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  ConsumerState<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends ConsumerState<DriverAttendanceScreen> {
  final Set<String> _presentIds = {};
  bool _isSaving = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  final Color _primaryDriver = const Color(0xFF0D4D3A);
  final Color _accentDriver = const Color(0xFFFFD600);
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
    // FIX: Removing const as LocationSettings might not be constant in all versions
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) setState(() => _currentPosition = position);
    });
  }

  double _getDistanceToStudent(double? lat, double? lng) {
    if (_currentPosition == null || lat == null || lng == null) return 999999;
    return Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
  }

  Future<void> _confirmArrivalAtSchool(List<dynamic> students, String unitCode) async {
    setState(() => _isSaving = true);
    
    try {
      int count = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      for (var student in students) {
        final studentId = student['id'];
        final parentUid = student['parentId'];

        final studentRef = FirebaseFirestore.instance
            .collection('companies').doc(unitCode).collection('students').doc(studentId);
        batch.update(studentRef, {
          'last_arrival': Timestamp.fromDate(now),
          'attendance_status': _presentIds.contains(studentId) ? 'arrived_at_school' : 'not_picked_up'
        });
        count++;

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
          count++;
        }

        if (count >= 390) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
      
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _accentDriver, borderRadius: BorderRadius.circular(12)),
                            child: Text(unitCode, style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w900, color: _primaryDriver)),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
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
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final s = students[index];
                                  final id = s['id'];
                                  final isAbsent = s['status'] == 'absent' || s['attendance_status'] == 'absent_today';
                                  final isPresent = _presentIds.contains(id);
                                  return _studentTile(s, isPresent, isAbsent);
                                },
                              ),
                            const SizedBox(height: 40),
                            _confirmArrivalButton(students, unitCode),
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

  Widget _statCircle(double percent) {
    return SizedBox(
      width: 60, height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: percent, strokeWidth: 8, backgroundColor: _primaryDriver.withValues(alpha: 0.05), color: _primaryDriver),
          Text('${(percent * 100).toInt()}%', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w900, color: _primaryDriver)),
        ],
      ),
    );
  }

  Widget _studentTile(dynamic s, bool isPresent, bool isAbsent) {
    final dist = _getDistanceToStudent(s['stopLat'] as double?, s['stopLng'] as double?);
    final isNear = dist <= 200; // Umbral de 200 metros

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNear ? (isPresent ? _primaryDriver.withValues(alpha: 0.1) : Colors.transparent) : Colors.orange.withValues(alpha: 0.3),
          width: isNear ? 1 : 2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAbsent ? Colors.red.shade50 : (isNear ? _primaryDriver.withValues(alpha: 0.05) : Colors.orange.shade50),
            child: Icon(
              isAbsent ? Icons.person_off_rounded : (isNear ? Icons.person_rounded : Icons.location_off_rounded), 
              color: isAbsent ? Colors.red : (isNear ? _primaryDriver : Colors.orange.shade700), 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['studentName'] ?? 'Estudiante', style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.w900, color: _primaryDriver)),
                Row(
                  children: [
                    Text(
                      isAbsent ? 'INASISTENCIA' : (isPresent ? 'EN EL BUS' : 'POR RECOGER'), 
                      style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.bold, color: isAbsent ? Colors.red : (isPresent ? const Color(0xFF167159) : Colors.grey))
                    ),
                    if (!isAbsent && dist < 100000) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${dist.toInt()}m',
                        style: GoogleFonts.publicSans(fontSize: 9, fontWeight: FontWeight.bold, color: isNear ? Colors.green : Colors.orange.shade700),
                      ),
                    ],
                  ],
                ),
                if (!isNear && !isAbsent)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('FUERA DE RANGO (PARADA LEJOS)', style: GoogleFonts.publicSans(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
                  ),
              ],
            ),
          ),
          if (!isAbsent)
            Switch(
              value: isPresent, 
              activeThumbColor: _primaryDriver,
              activeTrackColor: _primaryDriver.withValues(alpha: 0.2),
              onChanged: (val) async {
                if (!isNear && val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ Estás a ${dist.toInt()}m. Debes estar cerca de la parada para marcar.'),
                      backgroundColor: Colors.orange.shade900,
                      duration: const Duration(seconds: 2),
                    )
                  );
                }
                setState(() {
                  if (val) {
                    _presentIds.add(s['id'] as String);
                  } else {
                    _presentIds.remove(s['id'] as String);
                  }
                });

                if (val) {
                  final parentUid = s['parentId'] as String?;
                  if (parentUid != null) {
                    try {
                      final notificationRef = FirebaseFirestore.instance
                          .collection('users').doc('parents').collection('members').doc(parentUid)
                          .collection('notifications').doc();
                      
                      await notificationRef.set({
                        'title': '✅ Estudiante a bordo',
                        'message': '${s['studentName']} ha subido al transporte seguro.',
                        'timestamp': Timestamp.now(),
                        'type': 'boarded',
                        'isRead': false,
                      });
                    } catch (e) {
                      debugPrint('Error enviando notificación: $e');
                    }
                  }
                }
              }
            ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text('No hay estudiantes asignados hoy', style: GoogleFonts.publicSans(color: Colors.grey))));

  Widget _confirmArrivalButton(List<dynamic> students, String unitCode) {
    return ElevatedButton(
      onPressed: _isSaving ? null : () => _confirmArrivalAtSchool(students, unitCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryDriver,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10, shadowColor: _primaryDriver.withValues(alpha: 0.4),
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
