import '../entity/app_user.dart';
import '../repository/auth_repository.dart';

class SignInWithGoogle {
  SignInWithGoogle(this._repo);

  final AuthRepository _repo;

  Future<AppUser> call() => _repo.signInWithGoogle();
}
