class AttendanceModel {
  final String studentId;
  final String status; // 'boarded', 'absent', 'pending'
  final DateTime? timestamp;

  AttendanceModel({
    required this.studentId,
    this.status = 'pending',
    this.timestamp,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      studentId: map['studentId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'status': status,
      'timestamp': timestamp?.millisecondsSinceEpoch,
    };
  }
}
