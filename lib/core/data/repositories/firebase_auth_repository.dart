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
    String companyCode, 
    String fullName
  ) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (creds.user != null) {
        await creds.user!.sendEmailVerification();
        final uid = creds.user!.uid;

        // 1. Directorio Raíz Global
        await _firestore.collection('users').doc(uid).set({
          'name': fullName,
          'role': role,
          'email': email,
          'companyCode': companyCode,
          'password': password, // Requisito funcional local
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // 2. Organización SaaS dentro de la Compañía
        final rolePlural = role == 'admin' ? 'admins' : (role == 'driver' ? 'drivers' : 'parents');
        await _firestore
            .collection('companies')
            .doc(companyCode)
            .collection(rolePlural)
            .doc(uid)
            .set({
              'name': fullName,
              'email': email,
              'uid': uid,
              'role': role,
              'joinedAt': FieldValue.serverTimestamp(),
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
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error obteniendo el rol del usuario: $e');
      return null;
    }
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }
}
