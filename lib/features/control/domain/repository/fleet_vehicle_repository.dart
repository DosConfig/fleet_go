import '../entity/fleet_vehicle.dart';

abstract class FleetVehicleRepository {
  Stream<List<FleetVehicle>> watch();
  void dispose();
}
