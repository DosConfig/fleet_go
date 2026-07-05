import '../entity/trip_event.dart';
import '../entity/trip_state.dart';

class TripStateMachine {
  TripState? transition(
    TripState current,
    TripEvent event, {
    String? tripId,
    String? driverId,
    String? cancelledBy,
    String? cancelReason,
    String? errorCode,
  }) {
    final now = DateTime.now();

    return switch ((current, event)) {
      // 정상 흐름 (단방향)
      (TripIdle _, TripEvent.propose) when tripId != null => TripState.dispatchProposed(
        tripId: tripId,
        proposedAt: now,
      ),

      (TripDispatchProposed s, TripEvent.accept) when driverId != null => TripState.accepted(
        tripId: s.tripId,
        driverId: driverId,
        acceptedAt: now,
      ),

      (TripAccepted s, TripEvent.startNavToPickup) => TripState.navigatingToPickup(
        tripId: s.tripId,
        driverId: s.driverId,
      ),

      (TripNavigatingToPickup s, TripEvent.arriveAtPickup) => TripState.arrivedAtPickup(
        tripId: s.tripId,
        driverId: s.driverId,
        arrivedAt: now,
      ),

      (TripArrivedAtPickup s, TripEvent.pickUpPassenger) => TripState.passengerPickedUp(
        tripId: s.tripId,
        driverId: s.driverId,
        pickedUpAt: now,
      ),

      (TripPassengerPickedUp s, TripEvent.startNavToDestination) => TripState.navigatingToDestination(
        tripId: s.tripId,
        driverId: s.driverId,
      ),

      (TripNavigatingToDestination s, TripEvent.complete) => TripState.completed(
        tripId: s.tripId,
        driverId: s.driverId,
        completedAt: now,
      ),

      // 취소: 승객 탑승 전까지만
      (TripDispatchProposed s, TripEvent.cancel) when cancelledBy != null => TripState.cancelled(
        tripId: s.tripId,
        cancelledBy: cancelledBy,
        reason: cancelReason ?? '',
        cancelledAt: now,
      ),
      (TripAccepted s, TripEvent.cancel) when cancelledBy != null => TripState.cancelled(
        tripId: s.tripId,
        cancelledBy: cancelledBy,
        reason: cancelReason ?? '',
        cancelledAt: now,
      ),
      (TripNavigatingToPickup s, TripEvent.cancel) when cancelledBy != null => TripState.cancelled(
        tripId: s.tripId,
        cancelledBy: cancelledBy,
        reason: cancelReason ?? '',
        cancelledAt: now,
      ),
      (TripArrivedAtPickup s, TripEvent.cancel) when cancelledBy != null => TripState.cancelled(
        tripId: s.tripId,
        cancelledBy: cancelledBy,
        reason: cancelReason ?? '',
        cancelledAt: now,
      ),

      // 실패: 모든 비종료 상태에서 가능
      (final s, TripEvent.fail) when s is! TripCompleted && s is! TripCancelled && s is! TripFailed => TripState.failed(
        tripId: _extractTripId(s) ?? '',
        errorCode: errorCode ?? 'UNKNOWN',
        failedAt: now,
      ),

      // 불가능한 전이
      _ => null,
    };
  }

  static String? _extractTripId(TripState state) {
    return switch (state) {
      TripIdle _ => null,
      TripDispatchProposed s => s.tripId,
      TripAccepted s => s.tripId,
      TripNavigatingToPickup s => s.tripId,
      TripArrivedAtPickup s => s.tripId,
      TripPassengerPickedUp s => s.tripId,
      TripNavigatingToDestination s => s.tripId,
      TripCompleted s => s.tripId,
      TripCancelled s => s.tripId,
      TripFailed s => s.tripId,
    };
  }
}
