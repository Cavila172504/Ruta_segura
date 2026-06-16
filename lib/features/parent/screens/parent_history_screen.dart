import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/parent_provider.dart';
import 'parent_dashboard_screen.dart';
import 'parent_map_screen.dart';
import 'parent_notifications_screen.dart';

class ParentHistoryScreen extends ConsumerStatefulWidget {
  const ParentHistoryScreen({super.key});

  @override
  ConsumerState<ParentHistoryScreen> createState() => _ParentHistoryScreenState();
}

class _ParentHistoryScreenState extends ConsumerState<ParentHistoryScreen> {
  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surface = const Color(0xFFF8F9FA);

  late DateTime _selectedDate;
  late final List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _weekDays = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return DateTime(day.year, day.month, day.day);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dayShort(DateTime date) {
    const days = ['DOM', 'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'];
    return days[date.weekday % 7];
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    DateTime dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is DateTime) {
      dt = value;
    } else {
      return '--:--';
    }
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _tripDurationMinutes(Map<String, dynamic> trip) {
    final start = trip['startedAt'];
    final end = trip['finishedAt'];
    if (start is! Timestamp || end is! Timestamp) return 0;
    return end.toDate().difference(start.toDate()).inMinutes.clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final unitCode = ref.watch(activeUnitCodeProvider).asData?.value;
    final companyName = unitCode != null
        ? (ref.watch(companyByUnitProvider(unitCode)).asData?.value?['name']?.toString())
        : null;

    if (unitCode == null || unitCode.isEmpty || uid == null) {
      return Scaffold(
        backgroundColor: _surface,
        body: _buildBody(context, uid, unitCode, companyName, const [], const []),
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(unitCode.trim().toUpperCase())
            .collection('trip_logs')
            .orderBy('finishedAt', descending: true)
            .limit(60)
            .snapshots(),
        builder: (context, tripSnap) {
          final allTrips = tripSnap.data?.docs
                  .map((d) => {'id': d.id, ...d.data()})
                  .where((t) {
                    final parents = t['parentIds'];
                    return parents is List && parents.contains(uid);
                  })
                  .toList() ??
              [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(unitCode.trim().toUpperCase())
                .collection('incidents')
                .orderBy('timestamp', descending: true)
                .limit(40)
                .snapshots(),
            builder: (context, incSnap) {
              final allIncidents = incSnap.data?.docs
                      .map((d) => {'id': d.id, ...d.data()})
                      .where((i) {
                        final parents = i['parentIds'];
                        return parents is List && parents.contains(uid);
                      })
                      .toList() ??
                  [];

              return _buildBody(context, uid, unitCode, companyName ?? unitCode, allTrips, allIncidents);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String? uid,
    String? unitCode,
    String? companyName,
    List<Map<String, dynamic>> allTrips,
    List<Map<String, dynamic>> allIncidents,
  ) {
    final dayTrips = allTrips.where((trip) {
      final finished = trip['finishedAt'];
      if (finished is! Timestamp) return false;
      return _isSameDay(finished.toDate(), _selectedDate);
    }).toList();

    final dayIncidents = allIncidents.where((inc) {
      final ts = inc['timestamp'];
      if (ts is! Timestamp) return false;
      return _isSameDay(ts.toDate(), _selectedDate);
    }).toList();

    final monthTrips = allTrips.where((trip) {
      final finished = trip['finishedAt'];
      if (finished is! Timestamp) return false;
      final d = finished.toDate();
      return d.year == _selectedDate.year && d.month == _selectedDate.month;
    }).toList();

    final totalDuration = monthTrips.fold<int>(0, (sum, t) => sum + _tripDurationMinutes(t));
    final avgMinutes = monthTrips.isEmpty ? 0 : (totalDuration / monthTrips.length).round();

    final totalPresent = monthTrips.fold<int>(0, (sum, t) {
      final summary = t['attendanceSummary'];
      if (summary is Map && summary['present'] is num) {
        return sum + (summary['present'] as num).toInt();
      }
      return sum;
    });
    final totalSlots = monthTrips.fold<int>(0, (sum, t) {
      final summary = t['attendanceSummary'];
      if (summary is Map) {
        final present = summary['present'] is num ? (summary['present'] as num).toInt() : 0;
        final absent = summary['absent'] is num ? (summary['absent'] as num).toInt() : 0;
        return sum + present + absent;
      }
      return sum;
    });
    final attendancePct = totalSlots == 0 ? 0 : ((totalPresent / totalSlots) * 100).round();

    final selectedTrip = dayTrips.isNotEmpty ? dayTrips.first : null;

    return Stack(
      children: [
        Positioned.fill(
          bottom: 80,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HISTORIAL DE RUTAS',
                  style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF727782)),
                ),
                const SizedBox(height: 4),
                Text(
                  _monthLabel(_selectedDate),
                  style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF191c1d), letterSpacing: -0.5),
                ),
                const SizedBox(height: 32),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _weekDays.map((day) {
                      final isActive = _isSameDay(day, _selectedDate);
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDate = day),
                          child: _buildDayCard(day: _dayShort(day), date: '${day.day}', isActive: isActive),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 40),
                if (unitCode == null || uid == null)
                  _emptyState('Vincula un colegio para ver el historial de rutas.')
                else if (selectedTrip == null)
                  _emptyState('No hay recorridos registrados para este día.')
                else
                  _buildTripCard(selectedTrip, companyName ?? unitCode, dayIncidents),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFFedeeef), borderRadius: BorderRadius.circular(32)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.trending_up, color: _primary),
                            const SizedBox(height: 8),
                            Text('$attendancePct%', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            Text('Asistencia Mensual', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF424751))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFFedeeef), borderRadius: BorderRadius.circular(32)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule, color: Color(0xFF6f3800)),
                            const SizedBox(height: 8),
                            Text('$avgMinutes min', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            Text('Tiempo Promedio', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF424751))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
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
                      Text('RutaSegura', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w800, color: _primary, letterSpacing: -0.5)),
                    ],
                  ),
                  Icon(Icons.notifications, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(context, icon: Icons.home, label: 'Inicio', isActive: false, target: const ParentDashboardScreen()),
                  _navItem(context, icon: Icons.map, label: 'Mapa', isActive: false, target: const ParentMapScreen()),
                  _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: false, target: const ParentNotificationsScreen()),
                  _navItem(context, icon: Icons.history, label: 'Historial', isActive: true, target: const ParentHistoryScreen()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751)),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, String companyName, List<Map<String, dynamic>> incidents) {
    final routeName = trip['routeName']?.toString() ?? 'Recorrido escolar';
    final driverName = trip['driverName']?.toString() ?? 'Conductor';
    final started = _formatTime(trip['startedAt']);
    final finished = _formatTime(trip['finishedAt']);
    final duration = _tripDurationMinutes(trip);
    final summary = trip['attendanceSummary'];
    final absent = summary is Map && summary['absent'] is num ? (summary['absent'] as num).toInt() : 0;
    final statusLabel = absent > 0 ? 'CON NOVEDAD' : 'COMPLETADO';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen del ${_dayShort(_selectedDate)[0]}${_dayShort(_selectedDate).substring(1).toLowerCase()} ${ _selectedDate.day}',
                            style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Ruta: $routeName • $companyName', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFd4e3ff), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel, style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004883))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _timeBox('SALIDA', started, 'Inicio del recorrido')),
                    const SizedBox(width: 16),
                    Expanded(child: _timeBox('LLEGADA', finished, 'Duración: $duration min')),
                  ],
                ),
                if (incidents.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFe1e3e4)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('INCIDENCIAS REPORTADAS', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF727782))),
                  ),
                  const SizedBox(height: 12),
                  ...incidents.map((inc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFffdcc4).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Color(0xFF6f3800)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(inc['type']?.toString() ?? 'Novedad', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2f1400))),
                                    Text(inc['description']?.toString() ?? '', style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF703800))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
          Container(
            color: const Color(0xFFd4e3ff),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.person, color: _primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONDUCTOR', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF004883))),
                      Text(driverName, style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF001c39)), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String label, String time, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFf3f4f5), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF727782))),
          const SizedBox(height: 8),
          Text(time, style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: _primary)),
          Text(subtitle, style: GoogleFonts.publicSans(fontSize: 11, color: const Color(0xFF424751))),
        ],
      ),
    );
  }

  Widget _buildDayCard({required String day, required String date, bool isActive = false}) {
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: isActive ? _primary : const Color(0xFFf3f4f5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isActive ? [BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF424751))),
          const SizedBox(height: 4),
          Text(date, style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF191c1d))),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget target}) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFdbeaFE) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? _primaryContainer : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? _primaryContainer : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
