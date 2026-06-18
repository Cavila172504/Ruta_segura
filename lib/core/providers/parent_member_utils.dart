import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

const Duration kFirestoreTimeout = Duration(seconds: 25);

Future<T> withNetworkTimeout<T>(
  Future<T> future, {
  Duration timeout = kFirestoreTimeout,
  String? message,
}) {
  return future.timeout(
    timeout,
    onTimeout: () => throw Exception(
      message ?? 'Sin conexion a internet. Verifica tu red e intenta de nuevo.',
    ),
  );
}

String friendlyNetworkError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('unknownhost') ||
      text.contains('unable to resolve host') ||
      text.contains('network is unreachable') ||
      text.contains('sin conexion')) {
    return 'Sin conexion a internet. Verifica tu red e intenta de nuevo.';
  }
  if (text.contains('timeout') || text.contains('deadline exceeded')) {
    return 'La operacion tardo demasiado. Revisa tu conexion e intenta otra vez.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

String normalizeUnitCode(String? code) {
  if (code == null) return '';
  return code.trim().toUpperCase();
}

String normalizeCedula(String? value) {
  if (value == null) return '';
  return value.replaceAll(RegExp(r'\D'), '');
}

Future<DocumentReference<Map<String, dynamic>>> ensureParentMemberRef(
  User user,
) async {
  final members = FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members');

  final docRef = members.doc(user.uid);
  final existing = await docRef.get();
  if (existing.exists) return docRef;

  await docRef.set({
    'uid': user.uid,
    'name': user.displayName ?? '',
    'email': user.email ?? '',
    'role': 'parent',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  return docRef;
}

Future<Map<String, dynamic>?> readParentMemberData(String uid) async {
  final direct = await FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .doc(uid)
      .get();
  if (direct.exists) return direct.data();

  final q = await FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .where('uid', isEqualTo: uid)
      .limit(1)
      .get();
  if (q.docs.isEmpty) return null;
  return q.docs.first.data();
}

String? resolveActiveUnitCode(Map<String, dynamic>? parentData) {
  if (parentData == null) return null;

  final active = normalizeUnitCode(parentData['activeUnitCode'] as String?);
  if (active.isNotEmpty) return active;

  final linked = parentData['linkedUnitCodes'];
  if (linked is List) {
    for (final item in linked) {
      final code = normalizeUnitCode(item?.toString());
      if (code.isNotEmpty) return code;
    }
  }
  return null;
}