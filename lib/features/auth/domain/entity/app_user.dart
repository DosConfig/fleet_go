import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({required String uid, required String name, required String email, String? photoUrl}) =
      _AppUser;
}
