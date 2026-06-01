import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'app_providers.dart';
import 'route_provider.dart';

final linkedUnitCodesProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final q = await FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .where('uid', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (q.docs.isEmpty) return [];

  final data = q.docs.first.data();
  final linked = <String>{};

  final fromList = data['linkedUnitCodes'];
  if (fromList is List) {
    for (final c in fromList) {
      if (c != null && c.toString().trim().isNotEmpty) {
        linked.add(c.toString().trim().toUpperCase());
      }
    }
  }

  final active = data['activeUnitCode'] as String?;
  if (active != null && active.trim().isNotEmpty) {
    linked.add(active.trim().toUpperCase());
  }

  final sub = await q.docs.first.reference.collection('students').get();
  for (final s in sub.docs) {
    final code = s.data()['unitCode'] as String?;
    if (code != null && code.isNotEmpty) linked.add(code.toUpperCase());
  }

  return linked.toList()..sort();
});

final companyByUnitProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, unitCode) async {
  final code = unitCode.trim().toUpperCase();
  if (code.isEmpty) return null;
  final snap =
      await FirebaseFirestore.instance.collection('companies').doc(code).get();
  if (!snap.exists) return null;
  return snap.data();
});

Future<DocumentReference<Map<String, dynamic>>> _parentMemberRef(String uid) async {
  final q = await FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .where('uid', isEqualTo: uid)
      .limit(1)
      .get();
  if (q.docs.isEmpty) {
    throw Exception('Perfil de padre no encontrado.');
  }
  return q.docs.first.reference;
}

Future<void> linkParentSchool(WidgetRef ref, String unitCode) async {
  final code = unitCode.trim().toUpperCase();
  if (code.length < 3) {
    throw Exception('Ingresa un codigo valido.');
  }

  final company =
      await FirebaseFirestore.instance.collection('companies').doc(code).get();
  if (!company.exists) {
    throw Exception('El codigo no esta registrado en RutaSegura.');
  }
  final name = company.data()?['name'] as String?;
  if (name == null || name.trim().isEmpty) {
    throw Exception('Este colegio no esta configurado correctamente.');
  }

  final user = ref.read(authStateProvider).value;
  if (user == null) throw Exception('Sesion no valida');

  final memberRef = await _parentMemberRef(user.uid);
  await memberRef.set({
    'linkedUnitCodes': FieldValue.arrayUnion([code]),
    'activeUnitCode': code,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await NotificationService().subscribeToBus(code);

  ref.invalidate(linkedUnitCodesProvider);
  ref.invalidate(activeUnitCodeProvider);
  ref.invalidate(parentStudentsProvider);
}

Future<void> setParentActiveUnit(WidgetRef ref, String unitCode) async {
  final code = unitCode.trim().toUpperCase();
  final user = ref.read(authStateProvider).value;
  if (user == null) return;

  final memberRef = await _parentMemberRef(user.uid);
  await memberRef.set({
    'activeUnitCode': code,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  ref.invalidate(activeUnitCodeProvider);
  ref.invalidate(parentStudentsProvider);
}

Future<void> subscribeParentToAllLinkedBuses(WidgetRef ref) async {
  final codes = await ref.read(linkedUnitCodesProvider.future);
  for (final code in codes) {
    await NotificationService().subscribeToBus(code);
  }
}
