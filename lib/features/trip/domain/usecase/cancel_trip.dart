import '../entity/trip_event.dart';
import '../repository/trip_repository.dart';
import 'trip_state_machine.dart';

class CancelTrip {
  CancelTrip(this._repo, this._machine);

  final TripRepository _repo;
  final TripStateMachine _machine;

  Future<void> call({required String tripId, required String cancelledBy, String? reason}) {
    return _repo.transitionTrip(
      tripId: tripId,
      transition: (currentState) {
        final nextState = _machine.transition(
          currentState,
          TripEvent.cancel,
          cancelledBy: cancelledBy,
          cancelReason: reason,
        );
        if (nextState == null) {
          throw Exception('취소 불가: 현재 상태 ${currentState.runtimeType}');
        }
        return nextState;
      },
    );
  }
}
