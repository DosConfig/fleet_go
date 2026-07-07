import '../../../location/domain/entity/vehicle_location.dart';

class VehicleLocationDto {
  VehicleLocationDto._();

  static Map<String, dynamic> toJson(VehicleLocation location) {
    return {
      'lat': location.lat,
      'lng': location.lng,
      'heading': location.heading,
      'speed': location.speed,
      'capturedAt': location.capturedAt.millisecondsSinceEpoch,
    };
  }

  static VehicleLocation fromJson(String vehicleId, Map<String, dynamic> json) {
    return VehicleLocation(
      vehicleId: vehicleId,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(json['capturedAt'] as int),
    );
  }
}
