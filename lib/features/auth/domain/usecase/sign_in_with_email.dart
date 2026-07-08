import '../entity/app_user.dart';
import '../repository/auth_repository.dart';

class SignInWithEmail {
  SignInWithEmail(this._repo);

  final AuthRepository _repo;

  Future<AppUser> call(String email, String password) => _repo.signInWithEmail(email, password);
}
