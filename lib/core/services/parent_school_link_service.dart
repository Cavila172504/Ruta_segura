import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../providers/parent_member_utils.dart';

class ParentSchoolLinkResult {
  const ParentSchoolLinkResult({
    required this.unitCode,
    required this.claimedCount,
  });

  final String unitCode;
  final int claimedCount;
}

Future<ParentSchoolLinkResult> linkParentSchoolWithCedula({
  required User user,
  required String unitCode,
  required String cedulaInput,
}) async {
  final code = normalizeUnitCode(unitCode);
  if (code.length < 3) {
    throw Exception('Ingresa un codigo valido.');
  }

  final cedulaNorm = normalizeCedula(cedulaInput);
  if (cedulaNorm.length < 6) {
    throw Exception('Ingresa una cedula valida.');
  }

  final company =
      await FirebaseFirestore.instance.collection('companies').doc(code).get();
  if (!company.exists) {
    throw Exception('El codigo no esta registrado en RutaSegura.');
  }

  final memberRef = await ensureParentMemberRef(user);

  // Guardar cedula y colegio ANTES de buscar estudiantes (las reglas lo exigen).
  await memberRef.set({
    'uid': user.uid,
    'name': user.displayName ?? memberRef.id,
    'email': user.email ?? '',
    'cedulaPadre': cedulaInput.trim(),
    'cedulaPadreNorm': cedulaNorm,
    'idNumber': cedulaInput.trim(),
    'linkedUnitCodes': FieldValue.arrayUnion([code]),
    'activeUnitCode': code,
    'onboardingComplete': true,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  var claimed = 0;
  try {
    claimed = await _claimPreEnrolledStudents(
      parentUid: user.uid,
      parentEmail: user.email ?? '',
      unitCode: code,
      cedulaNorm: cedulaNorm,
      cedulaRaw: cedulaInput.trim(),
      memberRef: memberRef,
    );
  } catch (e) {
    // Si falla el reclamo, el colegio queda vinculado igual.
    debugPrint('Claim estudiantes (no bloqueante): $e');
  }

  try {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(code)
        .collection('parents')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'cedulaPadreNorm': cedulaNorm,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Registro parents en company (no bloqueante): $e');
  }

  return ParentSchoolLinkResult(unitCode: code, claimedCount: claimed);
}

Future<int> _claimPreEnrolledStudents({
  required String parentUid,
  required String parentEmail,
  required String unitCode,
  required String cedulaNorm,
  required String cedulaRaw,
  required DocumentReference<Map<String, dynamic>> memberRef,
}) async {
  final studentsRef = FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('students');

  final seen = <String>{};
  final toClaim = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  void collect(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final doc in snap.docs) {
      if (seen.add(doc.id)) toClaim.add(doc);
    }
  }

  Future<void> runQuery(Query<Map<String, dynamic>> query) async {
    try {
      collect(await query.get());
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
  }

  // Consultas alineadas con reglas Firestore (cedula + sin parentId).
  await runQuery(
    studentsRef
        .where('cedulaPadreNorm', isEqualTo: cedulaNorm)
        .where('parentId', isEqualTo: ''),
  );
  await runQuery(
    studentsRef
        .where('cedulaPadreNorm', isEqualTo: cedulaNorm)
        .where('parentId', isNull: true),
  );
  await runQuery(
    studentsRef
        .where('cedulaPadre', isEqualTo: cedulaRaw)
        .where('parentId', isEqualTo: ''),
  );
  await runQuery(
    studentsRef
        .where('cedulaPadre', isEqualTo: cedulaRaw)
        .where('parentId', isNull: true),
  );
  if (cedulaRaw != cedulaNorm) {
    await runQuery(
      studentsRef
          .where('cedulaPadre', isEqualTo: cedulaNorm)
          .where('parentId', isEqualTo: ''),
    );
    await runQuery(
      studentsRef
          .where('cedulaPadre', isEqualTo: cedulaNorm)
          .where('parentId', isNull: true),
    );
  }

  var claimed = 0;
  for (final doc in toClaim) {
    final data = doc.data();
    final existingParent = data['parentId'] as String?;
    if (existingParent != null && existingParent.isNotEmpty) continue;

    final docCedulaNorm = normalizeCedula(
      data['cedulaPadreNorm'] as String? ?? data['cedulaPadre'] as String?,
    );
    if (docCedulaNorm != cedulaNorm) continue;

    await doc.reference.update({
      'parentId': parentUid,
      if (parentEmail.isNotEmpty) 'parentEmail': parentEmail,
      'cedulaPadreNorm': cedulaNorm,
      'claimedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await memberRef.collection('students').doc(doc.id).set({
      'studentId': doc.id,
      'studentName': data['studentName'] ?? data['name'] ?? '',
      'stopLat': data['stopLat'],
      'stopLng': data['stopLng'],
      'unitCode': unitCode,
      'grade': data['grade'],
      'photoUrl': data['photoUrl'],
      'serviceType': data['serviceType'],
      'status': data['status'] ?? 'active',
      'driverId': data['driverId'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    claimed++;
  }

  return claimed;
}

Future<bool> isParentSetupComplete(String uid) async {
  final data = await readParentMemberData(uid);
  if (data == null) return false;

  final code = resolveActiveUnitCode(data);
  if (code == null || code.isEmpty) return false;

  final cedula = normalizeCedula(
    data['cedulaPadreNorm'] as String? ??
        data['cedulaPadre'] as String? ??
        data['idNumber'] as String?,
  );
  return cedula.length >= 6;
}

String friendlyLinkError(Object error) {
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Permiso denegado en Firebase. Ejecuta: firebase deploy --only firestore:rules,firestore:indexes';
  }
  if (text.contains('not registered') || text.contains('no esta registrado')) {
    return 'El codigo del colegio no existe. Verificalo con la institucion.';
  }
  return text.replaceFirst('Exception: ', '');
}
