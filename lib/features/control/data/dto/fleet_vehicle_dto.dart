import 'package:freezed_annotation/freezed_annotation.dart';

part 'fleet_vehicle_dto.freezed.dart';
part 'fleet_vehicle_dto.g.dart';

@freezed
abstract class FleetVehicleDto with _$FleetVehicleDto {
  const factory FleetVehicleDto({
    required String vehicleId,
    required double lat,
    required double lng,
    @Default(0) double heading,
    @Default(0) double speed,
    required DateTime capturedAt,
  }) = _FleetVehicleDto;

  factory FleetVehicleDto.fromJson(Map<String, dynamic> json) =>
      _$FleetVehicleDtoFromJson(json);
}
