import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Stream provider to instantly react when user logs in or out
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Validación estricta de correo electrónico según requerimiento
      if (creds.user != null && !creds.user!.emailVerified) {
        // Enviar otro correo en caso de que lo hayan perdido
        await creds.user!.sendEmailVerification();
        await _auth.signOut();
        throw Exception('El correo no ha sido verificado. Hemos re-enviado el enlace, revisa tu SPAM o bandeja de entrada e intenta ingresar de nuevo.');
      }
      return creds;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUp(String email, String password, String role) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      if (creds.user != null) {
        // Enviar el correo de validación inmediatamente
        await creds.user!.sendEmailVerification();

        // ADVERTENCIA DE SEGURIDAD: Guardar la contraseña en texto plano
        // directamente en Firestore según la solicitud del usuario para fines de Soporte Local.
        await _firestore.collection('users').doc(creds.user!.uid).set({
          'role': role,
          'email': email,
          'password': password, // <- Almacenamiento en texto plano (Inseguro / Requisito Funcional)
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Cerramos la sesión localmente para obligarlo a verificar su correo antes de entrar
        await _auth.signOut();
      }
      return creds;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

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
}
