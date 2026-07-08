import 'dart:async';

import 'package:fleet_go/core/di/location_providers.dart';
import 'package:fleet_go/features/location/domain/entity/vehicle_location.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driver_providers.g.dart';

/// 드라이버 GPS → RTDB 위치 전송 시작/중지
@riverpod
class DriverLocationSender extends _$DriverLocationSender {
  StreamSubscription<void>? _subscription;

  @override
  bool build() => false;

  void start(String driverId) {
    if (state) return;
    state = true;

    final gps = ref.read(gpsDatasourceProvider);
    final updateLocation = ref.read(updateLocationProvider);

    _subscription = gps.watchPosition().listen((pos) {
      updateLocation.call(VehicleLocation(
        vehicleId: driverId,
        lat: pos.lat,
        lng: pos.lng,
        heading: pos.heading,
        speed: pos.speed,
        capturedAt: DateTime.now(),
      ));
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    state = false;
  }
}
