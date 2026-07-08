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
    return _watchActiveBy('passengerId', passengerId);
  }

  @override
  Stream<(String, TripState)?> watchActiveDriverTrip(String driverId) {
    return _watchActiveBy('driverId', driverId);
  }

  /// 특정 필드로 비종료 상태 trip을 실시간 조회하는 공용 헬퍼.
  Stream<(String, TripState)?> _watchActiveBy(String field, String value) {
    return _collection
        .where(field, isEqualTo: value)
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

    // 트랜잭션 내부에서 throw하면 cloud_firestore의 completer가
    // "Future already completed" 에러를 낼 수 있으므로,
    // 콜백 에러는 트랜잭션 밖에서 처리한다.
    Object? callbackError;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        callbackError = Exception('Trip not found: $tripId');
        return;
      }

      final dto = TripDto.fromJson(snapshot.data()!);
      final currentState = _toEntity(dto);
      if (currentState == null) {
        callbackError = Exception('Invalid trip state in Firestore: ${dto.status}');
        return;
      }

      try {
        final nextState = transition(currentState);
        final nextDto = _toDto(tripId, nextState);
        // passengerId를 모든 상태에서 보존 — watchActiveTrip 쿼리가 끊기지 않도록
        final preserved = nextDto.passengerId ?? dto.passengerId;
        transaction.set(docRef, nextDto.copyWith(passengerId: preserved).toJson());
      } catch (e) {
        callbackError = e;
      }
    });

    if (callbackError != null) {
      throw callbackError!;
    }
  }
}
