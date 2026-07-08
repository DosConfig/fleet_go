import '../entity/app_user.dart';
import '../repository/auth_repository.dart';

class SignUpWithEmail {
  SignUpWithEmail(this._repo);

  final AuthRepository _repo;

  Future<AppUser> call(String email, String password) => _repo.signUpWithEmail(email, password);
}
