import 'package:fleet_go/features/location/domain/entity/vehicle_location.dart';

abstract class LocationRepository {
  Future<void> updateLocation(VehicleLocation location);
  Stream<List<VehicleLocation>> watchAll();
  Stream<VehicleLocation?> watchVehicle(String vehicleId);
}
