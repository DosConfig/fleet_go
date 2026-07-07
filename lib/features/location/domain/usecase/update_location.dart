import '../entity/vehicle_location.dart';
import '../repository/location_repository.dart';

class UpdateLocation {
  UpdateLocation(this._repo);
  final LocationRepository _repo;

  Future<void> call(VehicleLocation location) => _repo.updateLocation(location);
}
