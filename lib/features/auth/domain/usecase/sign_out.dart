import '../repository/auth_repository.dart';

class SignOut {
  SignOut(this._repo);

  final AuthRepository _repo;

  Future<void> call() => _repo.signOut();
}
