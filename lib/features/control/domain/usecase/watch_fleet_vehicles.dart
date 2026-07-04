import '../entity/fleet_vehicle.dart';
import '../repository/fleet_vehicle_repository.dart';

class WatchFleetVehicles {
  WatchFleetVehicles(this._repository);
  final FleetVehicleRepository _repository;

  Stream<List<FleetVehicle>> call() => _repository.watch();
}
