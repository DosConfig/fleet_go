import 'package:freezed_annotation/freezed_annotation.dart';

part 'fleet_vehicle.freezed.dart';

@freezed
abstract class FleetVehicle with _$FleetVehicle {
  const factory FleetVehicle({
    required String vehicleId,
    required double lat,
    required double lng,
    @Default(0) double heading,
    @Default(0) double speed,
    required DateTime capturedAt,
  }) = _FleetVehicle;
}
