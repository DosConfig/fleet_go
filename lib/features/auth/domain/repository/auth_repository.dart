import 'package:fleet_go/features/auth/domain/entity/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}
