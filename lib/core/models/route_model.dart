class RouteModel {
  final String id;
  final String name;
  final String driverUid;
  final List<String> studentStops;
  final bool isActive;

  RouteModel({
    required this.id,
    required this.name,
    required this.driverUid,
    required this.studentStops,
    this.isActive = true,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RouteModel(
      id: documentId,
      name: map['name'] ?? '',
      driverUid: map['driverUid'] ?? '',
      studentStops: List<String>.from(map['studentStops'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'driverUid': driverUid,
      'studentStops': studentStops,
      'isActive': isActive,
    };
  }
}
