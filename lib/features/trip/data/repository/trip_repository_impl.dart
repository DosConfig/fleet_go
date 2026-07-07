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
      TripDispatchProposed(:final proposedAt, :final originLat, :final originLng, :final destLat, :final destLng) =>
        TripDto(
          tripId: tripId,
          status: 'dispatchProposed',
          proposedAt: proposedAt,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripAccepted(
        :final driverId,
        :final acceptedAt,
        :final originLat,
        :final originLng,
        :final destLat,
        :final destLng,
      ) =>
        TripDto(
          tripId: tripId,
          status: 'accepted',
          driverId: driverId,
          acceptedAt: acceptedAt,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripNavigatingToPickup(:final driverId, :final originLat, :final originLng, :final destLat, :final destLng) =>
        TripDto(
          tripId: tripId,
          status: 'navigatingToPickup',
          driverId: driverId,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripArrivedAtPickup(
        :final driverId,
        :final arrivedAt,
        :final originLat,
        :final originLng,
        :final destLat,
        :final destLng,
      ) =>
        TripDto(
          tripId: tripId,
          status: 'arrivedAtPickup',
          driverId: driverId,
          arrivedAt: arrivedAt,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripPassengerPickedUp(
        :final driverId,
        :final pickedUpAt,
        :final originLat,
        :final originLng,
        :final destLat,
        :final destLng,
      ) =>
        TripDto(
          tripId: tripId,
          status: 'passengerPickedUp',
          driverId: driverId,
          pickedUpAt: pickedUpAt,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripNavigatingToDestination(
        :final driverId,
        :final originLat,
        :final originLng,
        :final destLat,
        :final destLng,
      ) =>
        TripDto(
          tripId: tripId,
          status: 'navigatingToDestination',
          driverId: driverId,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripCompleted(
        :final driverId,
        :final completedAt,
        :final originLat,
        :final originLng,
        :final destLat,
        :final destLng,
      ) =>
        TripDto(
          tripId: tripId,
          status: 'completed',
          driverId: driverId,
          completedAt: completedAt,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ),
      TripCancelled(:final cancelledBy, :final reason, :final cancelledAt) => TripDto(
        tripId: tripId,
        status: 'cancelled',
        cancelledBy: cancelledBy,
        cancelReason: reason,
        cancelledAt: cancelledAt,
      ),
      TripFailed(:final errorCode, :final failedAt) => TripDto(
        tripId: tripId,
        status: 'failed',
        errorCode: errorCode,
        failedAt: failedAt,
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
}
