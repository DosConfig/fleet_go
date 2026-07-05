import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_state.freezed.dart';

@freezed
sealed class TripState with _$TripState {
  /// 대기 상태. 운행 없음.
  const factory TripState.idle() = TripIdle;

  /// 배차 제안됨. 시스템이 드라이버에게 배차를 제안한 상태.
  const factory TripState.dispatchProposed({required String tripId, required DateTime proposedAt}) =
      TripDispatchProposed;

  /// 배차 수락됨. 드라이버가 수락.
  const factory TripState.accepted({required String tripId, required String driverId, required DateTime acceptedAt}) =
      TripAccepted;

  /// 픽업지로 이동 중.
  const factory TripState.navigatingToPickup({required String tripId, required String driverId}) =
      TripNavigatingToPickup;

  /// 픽업지 도착.
  const factory TripState.arrivedAtPickup({
    required String tripId,
    required String driverId,
    required DateTime arrivedAt,
  }) = TripArrivedAtPickup;

  /// 승객 탑승 완료.
  const factory TripState.passengerPickedUp({
    required String tripId,
    required String driverId,
    required DateTime pickedUpAt,
  }) = TripPassengerPickedUp;

  /// 목적지로 이동 중.
  const factory TripState.navigatingToDestination({required String tripId, required String driverId}) =
      TripNavigatingToDestination;

  /// 운행 완료. 터미널 상태.
  const factory TripState.completed({required String tripId, required String driverId, required DateTime completedAt}) =
      TripCompleted;

  /// 취소됨. 터미널 상태.
  const factory TripState.cancelled({
    required String tripId,
    required String cancelledBy,
    required String reason,
    required DateTime cancelledAt,
  }) = TripCancelled;

  /// 실패, 터미널 상태.
  const factory TripState.failed({required String tripId, required String errorCode, required DateTime failedAt}) =
      TripFailed;
}
