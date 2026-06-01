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
      final companySnap = await companyDocRef.get();

      if (!companySnap.exists) {
        throw Exception(
          'El código de colegio no está registrado. Verifica el código con tu institución.',
        );
      }

      final companyName = companySnap.data()?['name'] as String?;
      if (companyName == null || companyName.trim().isEmpty) {
        throw Exception(
          'Este colegio aún no está configurado correctamente. Contacta a soporte.',
        );
      }


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
        'status': 'pending',
        'unitCode': docId,
        'grade': grade,
        'photoUrl': photoUrl,
        'serviceType': serviceType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Perfil del padre indexado por uid (reglas Firestore + FCM)
      final parentMembers = _firestore
          .collection('users')
          .doc('parents')
          .collection('members');

      final uidDocRef = parentMembers.doc(parentId);
      final existingParent = await uidDocRef.get();
      final existingActive = existingParent.data()?['activeUnitCode'] as String?;
      final parentUpdates = <String, dynamic>{
        'uid': parentId,
        'linkedUnitCodes': FieldValue.arrayUnion([docId]),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // No pisar el colegio activo al registrar un hijo en otro código.
      if (existingActive == null || existingActive.trim().isEmpty) {
        parentUpdates['activeUnitCode'] = docId;
      }
      await uidDocRef.set(parentUpdates, SetOptions(merge: true));

      await uidDocRef.collection('students').doc(newStudentRef.id).set({
          'studentId': newStudentRef.id,
          'studentName': studentName,
          'stopLat': stopLat,
          'stopLng': stopLng,
          'unitCode': docId,
          'grade': grade,
          'photoUrl': photoUrl,
          'serviceType': serviceType,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
      });

      // Limpiar posible doc legacy (id = nombre) si existe
      final legacyQuery = await parentMembers
          .where('uid', isEqualTo: parentId)
          .get();
      for (final legacy in legacyQuery.docs) {
        if (legacy.id != parentId) {
          await legacy.reference.delete();
        }
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
