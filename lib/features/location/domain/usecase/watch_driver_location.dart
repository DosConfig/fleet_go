import '../entity/vehicle_location.dart';
import '../repository/location_repository.dart';

class WatchDriverLocation {
  WatchDriverLocation(this._repo);
  final LocationRepository _repo;

  Stream<VehicleLocation?> call(String driverId) => _repo.watchVehicle(driverId);
}
