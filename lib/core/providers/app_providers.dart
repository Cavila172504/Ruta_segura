import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/student_repository.dart';
import '../domain/repositories/tracking_repository.dart';

import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/firebase_student_repository.dart';
import '../data/repositories/firebase_tracking_repository.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return FirebaseStudentRepository();
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return FirebaseTrackingRepository();
});

// App State Providers (Reemplazando los del FirebaseService global)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final uid = await authRepo.getCurrentUserId();
  if (uid == null) return null;
  
  // Buscamos el perfil en la nueva estructura organizada por roles
  for (final roleCol in ['admins', 'parents', 'drivers']) {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(roleCol)
        .collection('members')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
  }
  return null;
});

// parentStudentsProvider movido a route_provider.dart para consistencia con el mapa.
