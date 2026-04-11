import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  
  Future<UserCredential?> signIn(String email, String password);
  
  Future<UserCredential?> signUp(
    String email, 
    String password, 
    String role, 
    String companyCode, 
    String fullName
  );
  
  Future<void> sendPasswordReset(String email);
  
  Future<void> signOut();
  
  Future<String?> getUserRole(String uid);
  
  Future<String?> getCurrentUserId();
}
