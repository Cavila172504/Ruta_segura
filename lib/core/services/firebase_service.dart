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

  Future<UserCredential?> signUp(String email, String password, String role, String companyCode) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      if (creds.user != null) {
        // Enviar el correo de validación inmediatamente
        await creds.user!.sendEmailVerification();

        final uid = creds.user!.uid;

        // 1. Directorio Raíz Global (Para saber rápido adónde mandarlo en el Login)
        await _firestore.collection('users').doc(uid).set({
          'role': role,
          'email': email,
          'companyCode': companyCode,
          'password': password, // <- Almacenamiento en texto plano (Inseguro / Requisito Funcional)
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // 2. Organización SaaS (Jerárquica) dentro de la Compañía
        // Guardamos copia en la subcolección correspondiente a su rol.
        final rolePlural = role == 'admin' ? 'admins' : (role == 'driver' ? 'drivers' : 'parents');
        await _firestore
            .collection('companies')
            .doc(companyCode)
            .collection(rolePlural)
            .doc(uid)
            .set({
              'email': email,
              'uid': uid,
              'role': role,
              'joinedAt': FieldValue.serverTimestamp(),
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

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<void> registerStudent({
    required String parentId,
    required String studentName,
    required String unitCode,
    required double stopLat,
    required double stopLng,
  }) async {
    try {
      // 1. Guardar el Estudiante dentro de la Compañía / Unidad
      await _firestore
          .collection('companies')
          .doc(unitCode)
          .collection('students')
          .add({
            'parentId': parentId,
            'studentName': studentName,
            'unitCode': unitCode,
            'stopLat': stopLat,
            'stopLng': stopLng,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

      // 2. Registrar al Padre dentro del listado de Clientes de esa Unidad/Compañía
      await _firestore
          .collection('companies')
          .doc(unitCode)
          .collection('parents')
          .doc(parentId)
          .set({
            'uid': parentId,
            'joinedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Merge evita borrar si el padre ya existía

    } catch (e) {
      throw Exception('No se pudo registrar al estudiante: $e');
    }
  }

  // ==========================================
  // GPS & LÓGICA DE PROXIMIDAD (GEOTRACKING)
  // ==========================================

  /// El Conductor llamará a este método cada X segundos para publicar su posición.
  Future<void> updateDriverLocation(String unitCode, double lat, double lng) async {
    try {
      await _firestore
          .collection('companies')
          .doc(unitCode)
          .collection('live_tracking')
          .doc('current')
          .set({
            'lat': lat,
            'lng': lng,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar posición del chofer: $e');
    }
  }

  /// App del Padre escucha este stream en tiempo real para recibir las coordenadas de la furgoneta.
  Stream<DocumentSnapshot> listenToDriverLocation(String unitCode) {
    return _firestore
        .collection('companies')
        .doc(unitCode)
        .collection('live_tracking')
        .doc('current')
        .snapshots();
  }
}

