import 'package:fleet_go/features/trip/domain/entity/trip_event.dart';
import 'package:fleet_go/features/trip/domain/repository/trip_repository.dart';
import 'package:fleet_go/features/trip/domain/usecase/trip_state_machine.dart';

class AdvanceTrip {
  AdvanceTrip(this._repo, this._machine);

  final TripRepository _repo;
  final TripStateMachine _machine;

  Future<void> call({
    required String tripId,
    required TripEvent event,
    String? cancelledBy,
    String? cancelReason,
    String? errorCode,
  }) {
    return _repo.transitionTrip(
      tripId: tripId,
      transition: (currentState) {
        final nextState = _machine.transition(
          currentState,
          event,
          cancelledBy: cancelledBy,
          cancelReason: cancelReason,
          errorCode: errorCode,
        );
        if (nextState == null) {
          throw Exception('전이 불가: ${currentState.runtimeType} + ${event.name}');
        }
        return nextState;
      },
    );
  }
}
