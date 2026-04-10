class StudentModel {
  final String id;
  final String name;
  final String routeId;
  final String parentUid;
  final double stopLatitude;
  final double stopLongitude;

  StudentModel({
    required this.id,
    required this.name,
    required this.routeId,
    required this.parentUid,
    required this.stopLatitude,
    required this.stopLongitude,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      id: documentId,
      name: map['name'] ?? '',
      routeId: map['routeId'] ?? '',
      parentUid: map['parentUid'] ?? '',
      stopLatitude: map['stopLatitude']?.toDouble() ?? 0.0,
      stopLongitude: map['stopLongitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'routeId': routeId,
      'parentUid': parentUid,
      'stopLatitude': stopLatitude,
      'stopLongitude': stopLongitude,
    };
  }
}
