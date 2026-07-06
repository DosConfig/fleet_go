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
      ),
      'accepted' => TripState.accepted(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        acceptedAt: dto.acceptedAt ?? DateTime.now(),
      ),
      'navigatingToPickup' => TripState.navigatingToPickup(tripId: dto.tripId, driverId: dto.driverId ?? ''),
      'arrivedAtPickup' => TripState.arrivedAtPickup(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        arrivedAt: dto.arrivedAt ?? DateTime.now(),
      ),
      'passengerPickedUp' => TripState.passengerPickedUp(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        pickedUpAt: dto.pickedUpAt ?? DateTime.now(),
      ),
      'navigatingToDestination' => TripState.navigatingToDestination(tripId: dto.tripId, driverId: dto.driverId ?? ''),
      'completed' => TripState.completed(
        tripId: dto.tripId,
        driverId: dto.driverId ?? '',
        completedAt: dto.completedAt ?? DateTime.now(),
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
    if (state is TripIdle) {
      return TripDto(tripId: tripId, status: 'idle');
    }
    if (state is TripDispatchProposed) {
      return TripDto(tripId: tripId, status: 'dispatchProposed', proposedAt: state.proposedAt);
    }
    if (state is TripAccepted) {
      return TripDto(tripId: tripId, status: 'accepted', driverId: state.driverId, acceptedAt: state.acceptedAt);
    }
    if (state is TripNavigatingToPickup) {
      return TripDto(tripId: tripId, status: 'navigatingToPickup', driverId: state.driverId);
    }
    if (state is TripArrivedAtPickup) {
      return TripDto(tripId: tripId, status: 'arrivedAtPickup', driverId: state.driverId, arrivedAt: state.arrivedAt);
    }
    if (state is TripPassengerPickedUp) {
      return TripDto(
        tripId: tripId,
        status: 'passengerPickedUp',
        driverId: state.driverId,
        pickedUpAt: state.pickedUpAt,
      );
    }
    if (state is TripNavigatingToDestination) {
      return TripDto(tripId: tripId, status: 'navigatingToDestination', driverId: state.driverId);
    }
    if (state is TripCompleted) {
      return TripDto(tripId: tripId, status: 'completed', driverId: state.driverId, completedAt: state.completedAt);
    }
    if (state is TripCancelled) {
      return TripDto(
        tripId: tripId,
        status: 'cancelled',
        cancelledBy: state.cancelledBy,
        cancelReason: state.reason,
        cancelledAt: state.cancelledAt,
      );
    }
    if (state is TripFailed) {
      return TripDto(tripId: tripId, status: 'failed', errorCode: state.errorCode, failedAt: state.failedAt);
    }
    return TripDto(tripId: tripId, status: 'idle');
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
