import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/fleet_vehicle_providers.dart';
import '../domain/entity/fleet_vehicle.dart';

part 'fleet_providers.g.dart';

@riverpod
Stream<List<FleetVehicle>> fleetSnapshots(Ref ref) {
  final usecase = ref.watch(watchFleetVehiclesProvider);
  return usecase();
}
