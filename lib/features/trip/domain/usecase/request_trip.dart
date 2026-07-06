import 'package:fleet_go/features/trip/domain/entity/trip_event.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:fleet_go/features/trip/domain/repository/trip_repository.dart';
import 'package:fleet_go/features/trip/domain/usecase/trip_state_machine.dart';

class RequestTrip {
  RequestTrip(this._repo, this._machine);

  final TripRepository _repo;
  final TripStateMachine _machine;

  Future<void> call({required String tripId}) {
    final state = _machine.transition(const TripState.idle(), TripEvent.propose, tripId: tripId);

    if (state == null) throw Exception('Invalid transition');
    return _repo.saveTrip(tripId, state);
  }
}
