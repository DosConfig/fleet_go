import '../entity/trip_state.dart';

/// Trip 저장/조회 추상 인터페이스. domain 레이어 — Firestore를 모름.
abstract class TripRepository {
  Future<TripState?> getTrip(String tripId);
  Future<void> saveTrip(String tripId, TripState state);
  Stream<TripState?> watchTrip(String tripId);
  Stream<List<(String tripId, TripState state)>> watchByStatus(String status);

  Future<void> transitionTrip({required String tripId, required TripState Function(TripState current) transition});

  /// 해당 승객의 활성(비종료) trip을 실시간 조회.
  /// 종료 상태(completed, cancelled, failed)가 아닌 trip 중 가장 최근 것을 반환.
  Stream<(String tripId, TripState state)?> watchActiveTrip(String passengerId);
}
