import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (creds.user != null && !creds.user!.emailVerified) {
        await creds.user!.sendEmailVerification();
        await _auth.signOut();
        throw Exception('El correo no ha sido verificado. Hemos re-enviado el enlace, revisa tu SPAM o bandeja de entrada e intenta ingresar de nuevo.');
      }
      return creds;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserCredential?> signUp(
    String email, 
    String password, 
    String role, 
    String fullName,
  ) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (creds.user != null) {
        await creds.user!.updateDisplayName(fullName);
        await creds.user!.sendEmailVerification();
        final uid = creds.user!.uid;

        // Mapeamos el rol a una subcoleccion legible
        final String roleCollection;
        switch (role) {
          case 'admin':  roleCollection = 'admins';  break;
          case 'driver': roleCollection = 'drivers'; break;
          default:       roleCollection = 'parents'; break;
        }

        // ID del documento = nombre limpio (sin espacios duplicados, en minúsculas)
        final docId = fullName.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();

        // 1. Guardamos en subcoleccion por rol: users/{rol}/{nombre}
        await _firestore
            .collection('users')
            .doc(roleCollection)
            .collection('members')
            .doc(docId)
            .set({
              'uid': uid,
              'name': fullName,
              'email': email,
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
            });

        await _auth.signOut();
      }
      return creds;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<String?> getUserRole(String uid) async {
    try {
      // Buscamos el rol en cada subcoleccion de roles con timeout de 10s
      for (final roleCollection in ['admins', 'parents', 'drivers']) {
        final query = await _firestore
            .collection('users')
            .doc(roleCollection)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (query.docs.isNotEmpty) {
          final role = query.docs.first.data()['role'] as String?;
          return role;
        }
      }
      // Si no se encontró en ninguna colección, asumir 'parent' como default
      return 'parent';
    } catch (e) {
      // En caso de timeout u otro error, default a 'parent'
      return 'parent';
    }
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }
}
