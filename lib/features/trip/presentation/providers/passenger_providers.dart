import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'passenger_providers.g.dart';

@riverpod
class PassengerTripId extends _$PassengerTripId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}
