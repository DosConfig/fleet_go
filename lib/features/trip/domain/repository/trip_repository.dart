import '../entity/trip_state.dart';

/// Trip 저장/조회 추상 인터페이스. domain 레이어 — Firestore를 모름.
abstract class TripRepository {
  Future<TripState?> getTrip(String tripId);
  Future<void> saveTrip(String tripId, TripState state);
  Stream<List<(String tripId, TripState state)>> watchByStatus(String status);
}
