import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/control/data/repository/fleet_vehicle_repository_impl.dart';
import '../../features/control/domain/repository/fleet_vehicle_repository.dart';
import '../../features/control/domain/usecase/watch_fleet_vehicles.dart';

part 'fleet_vehicle_providers.g.dart';

const _kMockTickInterval = Duration(milliseconds: 500);

/// 모의 차량 수. 벤치마크 러너가 런타임에 갈아끼우면
/// repository(isolate)가 새 규모로 재생성된다.
class MockFleetSize extends Notifier<int> {
  @override
  int build() => 1000;

  void set(int count) => state = count;
}

final mockFleetSizeProvider =
    NotifierProvider<MockFleetSize, int>(MockFleetSize.new);

@riverpod
FleetVehicleRepository fleetVehicleRepository(Ref ref) {
  final count = ref.watch(mockFleetSizeProvider);
  final repo = FleetVehicleRepositoryImpl(vehicleCount: count, tickInterval: _kMockTickInterval);
  ref.onDispose(repo.dispose);
  return repo;
}

@riverpod
WatchFleetVehicles watchFleetVehicles(Ref ref) {
  final repo = ref.watch(fleetVehicleRepositoryProvider);
  return WatchFleetVehicles(repo);
}
