import 'attendance_model.dart';

class TripModel {
  final String id;
  final String routeId;
  final String driverUid;
  final String status; // 'ongoing' or 'completed'
  final DateTime? startTime;
  final DateTime? endTime;
  final double currentLocationLat;
  final double currentLocationLng;
  final List<AttendanceModel> attendance;

  TripModel({
    required this.id,
    required this.routeId,
    required this.driverUid,
    this.status = 'ongoing',
    this.startTime,
    this.endTime,
    this.currentLocationLat = 0.0,
    this.currentLocationLng =  0.0,
    this.attendance = const [],
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TripModel(
      id: documentId,
      routeId: map['routeId'] ?? '',
      driverUid: map['driverUid'] ?? '',
      status: map['status'] ?? 'ongoing',
      startTime: map['startTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endTime']) : null,
      currentLocationLat: map['currentLocationLat']?.toDouble() ?? 0.0,
      currentLocationLng: map['currentLocationLng']?.toDouble() ?? 0.0,
      attendance: map['attendance'] != null 
        ? List<AttendanceModel>.from(map['attendance'].map((x) => AttendanceModel.fromMap(x))) 
        : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'driverUid': driverUid,
      'status': status,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'currentLocationLat': currentLocationLat,
      'currentLocationLng': currentLocationLng,
      'attendance': attendance.map((x) => x.toMap()).toList(),
    };
  }
}
