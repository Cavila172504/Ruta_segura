abstract class StudentRepository {
  Future<String> registerStudent({
    required String parentId,
    required String studentName,
    required String unitCode,
    required double stopLat,
    required double stopLng,
    required String cedulaPadre,
    String? grade,
    String? photoUrl,
    String? serviceType,
    String? parentName,
    String? parentEmail,
  });
}
