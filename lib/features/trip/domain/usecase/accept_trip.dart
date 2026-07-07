import 'package:fleet_go/features/trip/domain/entity/trip_event.dart';
import 'package:fleet_go/features/trip/domain/repository/trip_repository.dart';
import 'package:fleet_go/features/trip/domain/usecase/trip_state_machine.dart';

class AcceptTrip {
  AcceptTrip(this._repo, this._machine);

  final TripRepository _repo;
  final TripStateMachine _machine;

  Future<void> call({required String tripId, required String driverId}) {
    return _repo.transitionTrip(
      tripId: tripId,
      transition: (currentState) {
        final nextState = _machine.transition(currentState, TripEvent.accept, driverId: driverId);
        if (nextState == null) {
          throw Exception('수락 불가: 현재 상태 ${currentState.runtimeType}');
        }
        return nextState;
      },
    );
  }
}
