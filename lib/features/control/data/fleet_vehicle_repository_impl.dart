import 'dart:async';
import 'dart:math';

import '../domain/entity/fleet_vehicle.dart';
import '../domain/repository/fleet_vehicle_repository.dart';

class FleetVehicleRepositoryImpl implements FleetVehicleRepository {
  FleetVehicleRepositoryImpl();

  final _random = Random(42);
  final _controller = StreamController<List<FleetVehicle>>.broadcast();
  Timer? _timer;
  List<FleetVehicle> _vehicles = _initialVehicles();

  @override
  Stream<List<FleetVehicle>> watch() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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

  static List<FleetVehicle> _initialVehicles() {
    final now = DateTime.now();
    return [
      FleetVehicle(vehicleId: 'V-001', lat: 37.5665, lng: 126.9780, heading: 45, speed: 30, capturedAt: now),
      FleetVehicle(vehicleId: 'V-002', lat: 37.5700, lng: 126.9820, heading: 120, speed: 25, capturedAt: now),
      FleetVehicle(vehicleId: 'V-003', lat: 37.5630, lng: 126.9750, heading: 270, speed: 0, capturedAt: now),
    ];
  }
}
