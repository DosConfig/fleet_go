import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_position.freezed.dart';
part 'vehicle_position.g.dart';

@freezed
abstract class VehiclePosition with _$VehiclePosition {
  const factory VehiclePosition({
    required String vehicleId,
    required double lat,
    required double lng,
    @Default(0) double heading,
    @Default(0) double speed,
    required DateTime timestamp,
  }) = _VehiclePosition;

  factory VehiclePosition.fromJson(Map<String, dynamic> json) =>
      _$VehiclePositionFromJson(json);
}
