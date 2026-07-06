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
  }) async {
    final current = await _repo.getTrip(tripId);
    if (current == null) throw Exception('Trip not found');

    final next = _machine.transition(
      current,
      event,
      cancelledBy: cancelledBy,
      cancelReason: cancelReason,
      errorCode: errorCode,
    );

    if (next == null) throw Exception('Invalid transition');
    return _repo.saveTrip(tripId, next);
  }
}
