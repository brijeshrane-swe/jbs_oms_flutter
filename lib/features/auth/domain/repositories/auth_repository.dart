import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signUpWithEmail(String email, String password);
  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<bool> verifyClientCode(String code);
  Future<void> requestClientAccess(String email, String displayName);
}
