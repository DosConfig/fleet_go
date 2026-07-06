import 'package:fleet_go/features/trip/domain/entity/trip_event.dart';
import 'package:fleet_go/features/trip/domain/repository/trip_repository.dart';
import 'package:fleet_go/features/trip/domain/usecase/trip_state_machine.dart';

class AcceptTrip {
  AcceptTrip(this._repo, this._machine);

  final TripRepository _repo;
  final TripStateMachine _machine;

  Future<void> call({required String tripId, required String driverId}) async {
    final current = await _repo.getTrip(tripId);
    if (current == null) throw Exception('Trip not found');

    final next = _machine.transition(current, TripEvent.accept, driverId: driverId);
    if (next == null) throw Exception('Invalid transition');
    return _repo.saveTrip(tripId, next);
  }
}
