import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'passenger_providers.g.dart';

@riverpod
class PassengerLoading extends _$PassengerLoading {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
