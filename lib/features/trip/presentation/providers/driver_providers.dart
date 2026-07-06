import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driver_providers.g.dart';

@riverpod
class DriverTripId extends _$DriverTripId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}
