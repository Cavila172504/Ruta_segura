import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/student_repository.dart';

class FirebaseStudentRepository implements StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> registerStudent({
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
  }) async {
    try {
      final docId = unitCode.trim().toUpperCase();
      if (docId.isEmpty) throw Exception("El código de unidad no puede estar vacío.");

      final companyDocRef = _firestore.collection('companies').doc(docId);
      
      // Aseguramos que el documento de la unidad exista (lo creamos si no existe)
      await companyDocRef.set({
        'unitCode': docId,
        'lastUpdate': FieldValue.serverTimestamp(),
        'status': 'active',
      }, SetOptions(merge: true));


      final newStudentRef = _firestore.collection('companies').doc(docId).collection('students').doc();
      
      await newStudentRef.set({
        'id': newStudentRef.id,
        'parentId': parentId,
        'cedulaPadre': cedulaPadre,
        'parentName': parentName,
        'parentEmail': parentEmail,
        'studentName': studentName,
        'stopLat': stopLat,
        'stopLng': stopLng,
        'status': 'active',
        'unitCode': docId,
        'grade': grade,
        'photoUrl': photoUrl,
        'serviceType': serviceType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar perfil del padre: guardar activeUnitCode para el mapa
      final parentDocQuery = await _firestore
          .collection('users')
          .doc('parents')
          .collection('members')
          .where('uid', isEqualTo: parentId)
          .limit(1)
          .get();

      if (parentDocQuery.docs.isNotEmpty) {
        final parentDocRef = parentDocQuery.docs.first.reference;
        // Guardar unitCode activo y referencia al estudiante
        await parentDocRef.update({'activeUnitCode': docId});
        // Sub-colección de estudiantes bajo el perfil del padre
        await parentDocRef.collection('students').doc(newStudentRef.id).set({
          'studentId': newStudentRef.id,
          'studentName': studentName,
          'stopLat': stopLat,
          'stopLng': stopLng,
          'unitCode': docId,
          'grade': grade,
          'photoUrl': photoUrl,
          'serviceType': serviceType,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore
          .collection('companies')
          .doc(docId)
          .collection('parents')
          .doc(parentId)
          .set({
            'uid': parentId,
            'joinedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

    } catch (e) {
      throw Exception('No se pudo registrar al estudiante: $e');
    }
  }
}
