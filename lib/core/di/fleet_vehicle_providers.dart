import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/control/data/repository/fleet_vehicle_repository_impl.dart';
import '../../features/control/domain/repository/fleet_vehicle_repository.dart';
import '../../features/control/domain/usecase/watch_fleet_vehicles.dart';

part 'fleet_vehicle_providers.g.dart';

// 3 → 50 → 300으로 바꿔가며 성능 확인
const _kMockVehicleCount = 1000;
const _kMockTickInterval = Duration(milliseconds: 500);

@riverpod
FleetVehicleRepository fleetVehicleRepository(Ref ref) {
  final repo = FleetVehicleRepositoryImpl(vehicleCount: _kMockVehicleCount, tickInterval: _kMockTickInterval);
  ref.onDispose(repo.dispose);
  return repo;
}

@riverpod
WatchFleetVehicles watchFleetVehicles(Ref ref) {
  final repo = ref.watch(fleetVehicleRepositoryProvider);
  return WatchFleetVehicles(repo);
}
