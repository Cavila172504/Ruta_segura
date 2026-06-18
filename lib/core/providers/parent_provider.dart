import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/parent_school_link_service.dart';
import 'app_providers.dart';
import 'parent_member_utils.dart';
import 'route_provider.dart';

/// 0 = Inicio, 1 = Mapa, 2 = Notificaciones
class ParentShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    state = index.clamp(0, 2);
  }
}

final parentShellTabIndexProvider =
    NotifierProvider<ParentShellTabIndexNotifier, int>(
  ParentShellTabIndexNotifier.new,
);

final parentSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  return isParentSetupComplete(user.uid);
});

final linkedUnitCodesProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final data = await readParentMemberData(user.uid);
  if (data == null) return [];

  final linked = <String>{};

  final fromList = data['linkedUnitCodes'];
  if (fromList is List) {
    for (final c in fromList) {
      final code = normalizeUnitCode(c?.toString());
      if (code.isNotEmpty) linked.add(code);
    }
  }

  final active = normalizeUnitCode(data['activeUnitCode'] as String?);
  if (active.isNotEmpty) linked.add(active);

  final q = await FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .where('uid', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (q.docs.isNotEmpty) {
    final sub = await q.docs.first.reference.collection('students').get();
    for (final s in sub.docs) {
      final code = normalizeUnitCode(s.data()['unitCode'] as String?);
      if (code.isNotEmpty) linked.add(code);
    }
  }

  return linked.toList()..sort();
});

final companyByUnitProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, unitCode) async {
  final code = normalizeUnitCode(unitCode);
  if (code.isEmpty) return null;
  final snap =
      await FirebaseFirestore.instance.collection('companies').doc(code).get();
  if (!snap.exists) return null;
  return snap.data();
});

Future<ParentSchoolLinkResult> linkParentSchool(
  WidgetRef ref,
  String unitCode, {
  required String cedulaPadre,
}) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) throw Exception('Sesion no valida');

  final result = await linkParentSchoolWithCedula(
    user: user,
    unitCode: unitCode,
    cedulaInput: cedulaPadre,
  );

  await NotificationService().subscribeToBus(result.unitCode);

  ref.invalidate(linkedUnitCodesProvider);
  ref.invalidate(activeUnitCodeProvider);
  ref.invalidate(parentStudentsProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(parentSetupCompleteProvider);

  return result;
}

Future<void> setParentActiveUnit(WidgetRef ref, String unitCode) async {
  final code = normalizeUnitCode(unitCode);
  final user = ref.read(authStateProvider).value;
  if (user == null) return;

  final memberRef = await ensureParentMemberRef(user);
  await memberRef.set({
    'activeUnitCode': code,
    'linkedUnitCodes': FieldValue.arrayUnion([code]),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  ref.invalidate(activeUnitCodeProvider);
  ref.invalidate(parentStudentsProvider);
  ref.invalidate(linkedUnitCodesProvider);
  ref.invalidate(userProfileProvider);
}

Future<void> subscribeParentToAllLinkedBuses(WidgetRef ref) async {
  final codes = await ref.read(linkedUnitCodesProvider.future);
  for (final code in codes) {
    await NotificationService().subscribeToBus(code);
  }
}
