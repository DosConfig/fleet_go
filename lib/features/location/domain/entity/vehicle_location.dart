import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_location.freezed.dart';

@freezed
abstract class VehicleLocation with _$VehicleLocation {
  const factory VehicleLocation({
    required String vehicleId,
    required double lat,
    required double lng,
    required double heading,
    required double speed,
    required DateTime capturedAt,
  }) = _VehicleLocation;
}
