import '../domain/entity/trip_state.dart';

/// TripState에서 좌표 4개를 추출하는 공용 유틸.
/// 좌표를 가진 상태(dispatchProposed~completed)에서만 반환, 나머지 null.
(double originLat, double originLng, double destLat, double destLng)? extractTripCoords(TripState state) {
  return switch (state) {
    final TripDispatchProposed s => (s.originLat, s.originLng, s.destLat, s.destLng),
    final TripAccepted s => (s.originLat, s.originLng, s.destLat, s.destLng),
    final TripNavigatingToPickup s => (s.originLat, s.originLng, s.destLat, s.destLng),
    final TripArrivedAtPickup s => (s.originLat, s.originLng, s.destLat, s.destLng),
    final TripPassengerPickedUp s => (s.originLat, s.originLng, s.destLat, s.destLng),
    final TripNavigatingToDestination s => (s.originLat, s.originLng, s.destLat, s.destLng),
    final TripCompleted s => (s.originLat, s.originLng, s.destLat, s.destLng),
    _ => null,
  };
}

/// TripState에서 driverId 추출. 드라이버가 배정된 상태에서만 반환.
String? extractDriverId(TripState state) {
  return switch (state) {
    final TripAccepted s => s.driverId,
    final TripNavigatingToPickup s => s.driverId,
    final TripArrivedAtPickup s => s.driverId,
    final TripPassengerPickedUp s => s.driverId,
    final TripNavigatingToDestination s => s.driverId,
    final TripCompleted s => s.driverId,
    _ => null,
  };
}
