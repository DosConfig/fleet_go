import 'dart:async';
import 'dart:math';

import '../domain/entity/fleet_vehicle.dart';
import '../domain/repository/fleet_vehicle_repository.dart';

class FleetVehicleRepositoryImpl implements FleetVehicleRepository {
  FleetVehicleRepositoryImpl({
    this.vehicleCount = 3,
    this.tickInterval = const Duration(seconds: 1),
  });

  final int vehicleCount;
  final Duration tickInterval;
  final _random = Random(42);
  final _controller = StreamController<List<FleetVehicle>>.broadcast();
  Timer? _timer;
  late List<FleetVehicle> _vehicles = _generateVehicles();

  @override
  Stream<List<FleetVehicle>> watch() {
    _timer ??= Timer.periodic(tickInterval, (_) => _tick());
    return _controller.stream;
  }

  void _tick() {
    _vehicles = [
      for (final v in _vehicles)
        v.copyWith(
          lat: v.lat + (_random.nextDouble() - 0.5) * 0.001,
          lng: v.lng + (_random.nextDouble() - 0.5) * 0.001,
          capturedAt: DateTime.now(),
        ),
    ];
    _controller.add(_vehicles);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  // 서울 시청 중심 반경 ~2km 내 랜덤 배치
  List<FleetVehicle> _generateVehicles() {
    final now = DateTime.now();
    return List.generate(vehicleCount, (i) {
      final id = 'V-${(i + 1).toString().padLeft(3, '0')}';
      return FleetVehicle(
        vehicleId: id,
        lat: 37.5665 + (_random.nextDouble() - 0.5) * 0.04,
        lng: 126.9780 + (_random.nextDouble() - 0.5) * 0.04,
        heading: _random.nextDouble() * 360,
        speed: _random.nextDouble() * 60,
        capturedAt: now,
      );
    });
  }
}
