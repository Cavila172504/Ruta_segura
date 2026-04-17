import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final adminCompaniesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('companies').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  });
});

final adminStudentsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance.collectionGroup('students').snapshots().map((snapshot) {
    return snapshot.docs.length;
  });
});

final adminActiveBusesProvider = Provider.autoDispose<int>((ref) {
  final companies = ref.watch(adminCompaniesProvider).value ?? [];
  return companies.where((c) => c['status'] == 'active' || c['status'] == 'on_route').length;
});

final adminAllStudentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collectionGroup('students').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => {'docId': doc.id, 'companyPath': doc.reference.parent.parent?.id, ...doc.data()}).toList();
  });
});

Future<void> adminDeleteStudent(String companyId, String studentId, String parentId) async {
  final firestore = FirebaseFirestore.instance;
  // Delete from companies/{companyId}/students/{studentId}
  await firestore.collection('companies').doc(companyId).collection('students').doc(studentId).delete();
  
  // Also delete from users/parents/members/{parentId}/students/{studentId} to keep DB clean
  final parentDocs = await firestore.collection('users').doc('parents').collection('members').where('uid', isEqualTo: parentId).limit(1).get();
  if (parentDocs.docs.isNotEmpty) {
    await parentDocs.docs.first.reference.collection('students').doc(studentId).delete();
  }
}

Future<void> adminCreateRoute(String unitCode, String driverName, String startTime) async {
  final companyId = unitCode.trim().toUpperCase();
  if (companyId.isEmpty) throw Exception('Código de unidad inválido');
  await FirebaseFirestore.instance.collection('companies').doc(companyId).set({
    'unitCode': companyId,
    'status': 'inactive',
    'driverName': driverName,
    'startTime': startTime,
    'lastUpdate': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
