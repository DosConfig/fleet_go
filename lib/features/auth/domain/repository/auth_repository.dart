import 'package:fleet_go/features/auth/domain/entity/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String email, String password);
  Future<void> signOut();
}
