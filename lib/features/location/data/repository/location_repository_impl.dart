import 'package:firebase_database/firebase_database.dart';
import 'package:fleet_go/features/location/data/dto/vehicle_location_dto.dart';
import 'package:fleet_go/features/location/domain/entity/vehicle_location.dart';
import 'package:fleet_go/features/location/domain/repository/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._database);

  final FirebaseDatabase _database;

  DatabaseReference get _ref => _database.ref('locations');

  @override
  Future<void> updateLocation(VehicleLocation location) {
    return _ref.child(location.vehicleId).set(VehicleLocationDto.toJson(location));
  }

  @override
  Stream<List<VehicleLocation>> watchAll() {
    return _ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <VehicleLocation>[];
      final data = snapshot.value as Map<Object?, Object?>;
      return data.entries.map((entry) {
        final vehicleId = entry.key as String;
        final json = Map<String, dynamic>.from(entry.value as Map);
        return VehicleLocationDto.fromJson(vehicleId, json);
      }).toList();
    });
  }

  @override
  Stream<VehicleLocation?> watchVehicle(String vehicleId) {
    return _ref.child(vehicleId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return null;

      final json = Map<String, dynamic>.from(snapshot.value as Map);
      return VehicleLocationDto.fromJson(vehicleId, json);
    });
  }
}
