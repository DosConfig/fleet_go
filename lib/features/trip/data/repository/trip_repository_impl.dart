import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/trip_state.dart';
import '../../domain/repository/trip_repository.dart';
import '../dto/trip_dto.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('trips');

  @override
  Future<TripState?> getTrip(String tripId) async {
    final doc = await _collection.doc(tripId).get();
    if (!doc.exists) return null;
    final dto = TripDto.fromJson(doc.data()!);
    return _toEntity(dto);
  }

  @override
  Future<void> saveTrip(String tripId, TripState state) async {
    final dto = _toDto(tripId, state);
    await _collection.doc(tripId).set(dto.toJson());
  }

  @override
  Stream<List<(String, TripState)>> watchByStatus(String status) {
    return _collection
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final dto = TripDto.fromJson(doc.data());
                final entity = _toEntity(dto);
                return entity != null ? (doc.id, entity) : null;
              })
              .whereType<(String, TripState)>()
              .toList(),
        );
  }

  TripState? _toEntity(TripDto dto) {
    return switch (dto.status) {
      'idle' => const TripState.idle(),
      'dispatchProposed' => TripState.dispatchProposed(
        tripId: dto.tripId,
        passengerId: dto.passengerId ?? '',
        proposedAt: dto.proposedAt ?? DateTime.now(),
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'accepted' => TripState.accepted(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        acceptedAt: dto.acceptedAt ?? DateTime.now(),
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'navigatingToPickup' => TripState.navigatingToPickup(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'arrivedAtPickup' => TripState.arrivedAtPickup(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        arrivedAt: dto.arrivedAt ?? DateTime.now(),
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'passengerPickedUp' => TripState.passengerPickedUp(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        pickedUpAt: dto.pickedUpAt ?? DateTime.now(),
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'navigatingToDestination' => TripState.navigatingToDestination(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'completed' => TripState.completed(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        completedAt: dto.completedAt ?? DateTime.now(),
        originLat: dto.originLat ?? 0,
        originLng: dto.originLng ?? 0,
        destLat: dto.destLat ?? 0,
        destLng: dto.destLng ?? 0,
      ),
      'cancelled' => TripState.cancelled(
        tripId: dto.tripId,
        cancelledBy: dto.cancelledBy ?? '',
        reason: dto.cancelReason ?? '',
        cancelledAt: dto.cancelledAt ?? DateTime.now(),
      ),
      'failed' => TripState.failed(
        tripId: dto.tripId,
        errorCode: dto.errorCode ?? 'UNKNOWN',
        failedAt: dto.failedAt ?? DateTime.now(),
      ),
      _ => null,
    };
  }

  TripDto _toDto(String tripId, TripState state) {
    return switch (state) {
      TripIdle() => TripDto(tripId: tripId, status: 'idle'),
      final TripDispatchProposed s => TripDto(
        tripId: tripId,
        status: 'dispatchProposed',
        passengerId: s.passengerId,
        proposedAt: s.proposedAt,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripAccepted s => TripDto(
        tripId: tripId,
        status: 'accepted',
        driverId: s.driverId,
        acceptedAt: s.acceptedAt,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripNavigatingToPickup s => TripDto(
        tripId: tripId,
        status: 'navigatingToPickup',
        driverId: s.driverId,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripArrivedAtPickup s => TripDto(
        tripId: tripId,
        status: 'arrivedAtPickup',
        driverId: s.driverId,
        arrivedAt: s.arrivedAt,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripPassengerPickedUp s => TripDto(
        tripId: tripId,
        status: 'passengerPickedUp',
        driverId: s.driverId,
        pickedUpAt: s.pickedUpAt,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripNavigatingToDestination s => TripDto(
        tripId: tripId,
        status: 'navigatingToDestination',
        driverId: s.driverId,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripCompleted s => TripDto(
        tripId: tripId,
        status: 'completed',
        driverId: s.driverId,
        completedAt: s.completedAt,
        originLat: s.originLat,
        originLng: s.originLng,
        destLat: s.destLat,
        destLng: s.destLng,
      ),
      final TripCancelled s => TripDto(
        tripId: tripId,
        status: 'cancelled',
        cancelledBy: s.cancelledBy,
        cancelReason: s.reason,
        cancelledAt: s.cancelledAt,
      ),
      final TripFailed s => TripDto(
        tripId: tripId,
        status: 'failed',
        errorCode: s.errorCode,
        failedAt: s.failedAt,
      ),
    };
  }

  @override
  Stream<TripState?> watchTrip(String tripId) {
    return _collection.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final dto = TripDto.fromJson(doc.data()!);
      return _toEntity(dto);
    });
  }

  @override
  Stream<(String, TripState)?> watchActiveTrip(String passengerId) {
    // 비종료 상태인 trip 중 passengerId가 일치하는 것을 조회
    // Firestore는 != 쿼리를 직접 지원하지 않으므로,
    // passengerId로 필터 후 클라이언트에서 종료 상태 제외
    return _collection
        .where('passengerId', isEqualTo: passengerId)
        .snapshots()
        .map((snapshot) {
      final activeDocs = snapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status != null &&
            status != 'completed' &&
            status != 'cancelled' &&
            status != 'failed' &&
            status != 'idle';
      });
      if (activeDocs.isEmpty) return null;

      // 가장 최근 trip 반환
      final doc = activeDocs.first;
      final dto = TripDto.fromJson(doc.data());
      final entity = _toEntity(dto);
      if (entity == null) return null;
      return (doc.id, entity);
    });
  }

  @override
  Future<void> transitionTrip({
    required String tripId,
    required TripState Function(TripState current) transition,
  }) async {
    final docRef = _collection.doc(tripId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Trip not found: $tripId');
      }

      final dto = TripDto.fromJson(snapshot.data()!);
      final currentState = _toEntity(dto);
      if (currentState == null) {
        throw Exception('Invalid trip state in Firestore: ${dto.status}');
      }

      final nextState = transition(currentState);

      transaction.set(docRef, _toDto(tripId, nextState).toJson());
    });
  }
}
