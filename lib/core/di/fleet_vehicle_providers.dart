import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/control/data/fleet_vehicle_repository_impl.dart';
import '../../features/control/domain/repository/fleet_vehicle_repository.dart';
import '../../features/control/domain/usecase/watch_fleet_vehicles.dart';

part 'fleet_vehicle_providers.g.dart';

@riverpod
FleetVehicleRepository fleetVehicleRepository(Ref ref) {
  final repo = FleetVehicleRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
}

@riverpod
WatchFleetVehicles watchFleetVehicles(Ref ref) {
  final repo = ref.watch(fleetVehicleRepositoryProvider);
  return WatchFleetVehicles(repo);
}
