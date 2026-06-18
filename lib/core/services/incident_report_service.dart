import 'package:cloud_firestore/cloud_firestore.dart';

/// Registra incidentes reales en `incident_reports` (panel web).
class IncidentReportService {
  static const double speedLimitKmh = 80;
  static const int delayThresholdMinutes = 10;
  static const Duration speedAlertCooldown = Duration(minutes: 5);

  static DateTime? _lastSpeedAlertAt;

  static Future<void> create({
    required String unitCode,
    required String driverId,
    required String driverName,
    required String type,
    required String category,
    required String description,
    String? routeName,
    double? speed,
    double? speedLimit,
    double? lat,
    double? lng,
    int? delayMinutes,
    String? expectedArrival,
    String? actualArrival,
  }) async {
    final code = unitCode.trim().toUpperCase();
    if (code.isEmpty || driverId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(code)
        .collection('incident_reports')
        .add({
      'type': type,
      'category': category,
      'description': description,
      'driverId': driverId,
      'driverName': driverName,
      'routeName': routeName ?? '',
      if (speed != null) 'speed': speed,
      if (speedLimit != null) 'speedLimit': speedLimit,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (delayMinutes != null) 'delayMinutes': delayMinutes,
      if (expectedArrival != null) 'expectedArrival': expectedArrival,
      if (actualArrival != null) 'actualArrival': actualArrival,
      'status': 'open',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> reportSpeedIfNeeded({
    required String unitCode,
    required String driverId,
    required String driverName,
    required double speedKmh,
    String? routeName,
    double? lat,
    double? lng,
  }) async {
    if (speedKmh < speedLimitKmh) return;

    final now = DateTime.now();
    if (_lastSpeedAlertAt != null &&
        now.difference(_lastSpeedAlertAt!) < speedAlertCooldown) {
      return;
    }
    _lastSpeedAlertAt = now;

    await create(
      unitCode: unitCode,
      driverId: driverId,
      driverName: driverName,
      type: 'Exceso de velocidad',
      category: 'velocidad',
      description:
          'Unidad a ${speedKmh.toStringAsFixed(0)} km/h (límite ${speedLimitKmh.toInt()} km/h).',
      routeName: routeName,
      speed: speedKmh,
      speedLimit: speedLimitKmh,
      lat: lat,
      lng: lng,
    );
  }

  static Future<void> reportDelayIfNeeded({
    required String unitCode,
    required String driverId,
    required String driverName,
    required DateTime arrivalTime,
    String? routeName,
    String expectedTime = '07:30',
  }) async {
    final parts = expectedTime.split(':');
    if (parts.length < 2) return;

    final expected = DateTime(
      arrivalTime.year,
      arrivalTime.month,
      arrivalTime.day,
      int.tryParse(parts[0]) ?? 7,
      int.tryParse(parts[1]) ?? 30,
    );

    final delayMinutes = arrivalTime.difference(expected).inMinutes;
    if (delayMinutes <= delayThresholdMinutes) return;

    final actualStr =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';

    await create(
      unitCode: unitCode,
      driverId: driverId,
      driverName: driverName,
      type: 'Retraso en llegada',
      category: 'retraso',
      description:
          'Llegada al colegio a las $actualStr (esperado $expectedTime, +$delayMinutes min).',
      routeName: routeName,
      delayMinutes: delayMinutes,
      expectedArrival: expectedTime,
      actualArrival: actualStr,
    );
  }
}
