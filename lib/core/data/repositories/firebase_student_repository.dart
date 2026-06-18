import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/student_repository.dart';
import '../../providers/parent_member_utils.dart';

class FirebaseStudentRepository implements StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
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
  }) async {
    final docId = unitCode.trim().toUpperCase();
    if (docId.isEmpty) {
      throw Exception('El codigo de unidad no puede estar vacio.');
    }

    final companySnap = await withNetworkTimeout(
      _firestore.collection('companies').doc(docId).get(),
    );
    if (!companySnap.exists) {
      throw Exception(
        'El codigo de colegio no esta registrado. Verifica el codigo con tu institucion.',
      );
    }

    final newStudentRef =
        _firestore.collection('companies').doc(docId).collection('students').doc();

    final studentData = <String, dynamic>{
      'id': newStudentRef.id,
      'parentId': parentId,
      'cedulaPadre': cedulaPadre,
      'cedulaPadreNorm': normalizeCedula(cedulaPadre),
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
    };

    try {
      await withNetworkTimeout(newStudentRef.set(studentData));
    } catch (e) {
      throw Exception('No se pudo registrar al estudiante: $e');
    }

    final studentId = newStudentRef.id;
    _mirrorStudentRegistration(
      parentId: parentId,
      studentId: studentId,
      docId: docId,
      cedulaPadre: cedulaPadre,
      studentName: studentName,
      stopLat: stopLat,
      stopLng: stopLng,
      grade: grade,
      photoUrl: photoUrl,
      serviceType: serviceType,
    );

    return studentId;
  }

  void _mirrorStudentRegistration({
    required String parentId,
    required String studentId,
    required String docId,
    required String cedulaPadre,
    required String studentName,
    required double stopLat,
    required double stopLng,
    String? grade,
    String? photoUrl,
    String? serviceType,
  }) {
    Future<void>(() async {
      final uidDocRef = _firestore
          .collection('users')
          .doc('parents')
          .collection('members')
          .doc(parentId);

      try {
        final existingParent = await uidDocRef.get().timeout(kFirestoreTimeout);
        final existingActive = existingParent.data()?['activeUnitCode'] as String?;
        final parentUpdates = <String, dynamic>{
          'uid': parentId,
          'cedulaPadre': cedulaPadre,
          'cedulaPadreNorm': normalizeCedula(cedulaPadre),
          'linkedUnitCodes': FieldValue.arrayUnion([docId]),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (existingActive == null || existingActive.trim().isEmpty) {
          parentUpdates['activeUnitCode'] = docId;
        }
        await uidDocRef
            .set(parentUpdates, SetOptions(merge: true))
            .timeout(kFirestoreTimeout);
      } catch (e, st) {
        debugPrint('registerStudent: perfil padre (no bloqueante): $e\n$st');
      }

      try {
        await uidDocRef.collection('students').doc(studentId).set({
          'studentId': studentId,
          'studentName': studentName,
          'stopLat': stopLat,
          'stopLng': stopLng,
          'unitCode': docId,
          'grade': grade,
          'photoUrl': photoUrl,
          'serviceType': serviceType,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(kFirestoreTimeout);
      } catch (e, st) {
        debugPrint('registerStudent: espejo students padre (no bloqueante): $e\n$st');
      }

      try {
        await _firestore
            .collection('companies')
            .doc(docId)
            .collection('parents')
            .doc(parentId)
            .set({
          'uid': parentId,
          'cedulaPadreNorm': normalizeCedula(cedulaPadre),
          'joinedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(kFirestoreTimeout);
      } catch (e, st) {
        debugPrint('registerStudent: companies/parents (no bloqueante): $e\n$st');
      }
    });
  }
}
