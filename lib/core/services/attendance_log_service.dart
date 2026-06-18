import 'package:cloud_firestore/cloud_firestore.dart';

/// Persiste asistencia diaria para la sábana mensual del panel web.
class AttendanceLogService {
  static String dateKey([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String reportCodeFromStatus(String? status) {
    switch (status) {
      case 'absent_today':
      case 'absent':
        return 'F';
      case 'arrived_at_school':
      case 'in_bus':
      case 'dropped_off_at_home':
      case 'present':
        return 'P';
      default:
        return '-';
    }
  }

  static Future<void> upsert({
    required String unitCode,
    required String studentId,
    required String studentName,
    required String? driverId,
    required String status,
    required String source,
    String? grade,
    DateTime? date,
  }) async {
    final code = unitCode.trim().toUpperCase();
    if (code.isEmpty || studentId.isEmpty) return;

    final day = dateKey(date);
    final reportCode = reportCodeFromStatus(status);
    if (reportCode == '-') return;

    final logId = '${studentId}_$day';
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(code)
        .collection('attendance_logs')
        .doc(logId)
        .set({
      'studentId': studentId,
      'studentName': studentName,
      'grade': grade ?? '',
      'driverId': driverId ?? '',
      'date': day,
      'status': status,
      'reportCode': reportCode,
      'source': source,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
