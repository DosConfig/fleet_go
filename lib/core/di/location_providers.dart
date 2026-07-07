import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/location/data/repository/location_repository_impl.dart';
import '../../features/location/domain/datasource/gps_datasource.dart';
import '../../features/location/domain/entity/vehicle_location.dart';
import '../../features/location/domain/repository/location_repository.dart';
import '../../features/location/domain/usecase/update_location.dart';
import '../../features/location/domain/usecase/watch_driver_location.dart';

part 'location_providers.g.dart';

@riverpod
LocationRepository locationRepository(Ref ref) {
  return LocationRepositoryImpl(FirebaseDatabase.instance);
}

@riverpod
GpsDatasource gpsDatasource(Ref ref) {
  // TODO: 실 GPS 전환 시 DeviceGpsDatasource()로 교체
  final ds = _MockGpsDatasource(
    coordinates: [
      (lat: 37.4979, lng: 127.0276),
      (lat: 37.4985, lng: 127.0280),
      (lat: 37.5000, lng: 127.0290),
      (lat: 37.5050, lng: 127.0200),
      (lat: 37.5100, lng: 127.0100),
      (lat: 37.5200, lng: 127.0000),
      (lat: 37.5350, lng: 126.9850),
      (lat: 37.5450, lng: 126.9750),
      (lat: 37.5547, lng: 126.9707),
    ],
    intervalMs: 2000,
  );
  ref.onDispose(ds.dispose);
  return ds;
}

@riverpod
UpdateLocation updateLocation(Ref ref) {
  return UpdateLocation(ref.watch(locationRepositoryProvider));
}

@riverpod
WatchDriverLocation watchDriverLocation(Ref ref) {
  return WatchDriverLocation(ref.watch(locationRepositoryProvider));
}

@riverpod
Stream<VehicleLocation?> watchDriverLocationStream(Ref ref, String driverId) {
  return ref.watch(watchDriverLocationProvider).call(driverId);
}

// --- mock은 DI 파일 내에서만 정의 ---
class _MockGpsDatasource implements GpsDatasource {
  _MockGpsDatasource({required this.coordinates, this.intervalMs = 1000});

  final List<({double lat, double lng})> coordinates;
  final int intervalMs;
  final _controller = StreamController<({double lat, double lng, double heading, double speed})>.broadcast();
  Timer? _timer;
  int _index = 0;

  @override
  Stream<({double lat, double lng, double heading, double speed})> watchPosition() {
    _timer ??= Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (coordinates.isEmpty || _index >= coordinates.length) {
        _timer?.cancel();
        return;
      }
      final current = coordinates[_index];
      final previous = _index > 0 ? coordinates[_index - 1] : current;
      final heading = _heading(previous, current);
      _controller.add((lat: current.lat, lng: current.lng, heading: heading, speed: 30.0));
      _index++;
    });
    return _controller.stream;
  }

  static double _heading(({double lat, double lng}) from, ({double lat, double lng}) to) {
    final dLng = to.lng - from.lng;
    final dLat = to.lat - from.lat;
    if (dLng == 0 && dLat == 0) return 0;
    return atan2(dLng, dLat) * 180 / pi;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
