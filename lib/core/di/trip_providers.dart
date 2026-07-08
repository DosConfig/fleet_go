import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/trip/data/repository/trip_repository_impl.dart';
import '../../features/trip/domain/repository/trip_repository.dart';
import '../../features/trip/domain/usecase/accept_trip.dart';
import '../../features/trip/domain/usecase/advance_trip.dart';
import '../../features/trip/domain/usecase/cancel_trip.dart';
import '../../features/trip/domain/usecase/request_trip.dart';
import '../../features/trip/domain/usecase/trip_state_machine.dart';

part 'trip_providers.g.dart';

@riverpod
TripRepository tripRepository(Ref ref) {
  return TripRepositoryImpl(FirebaseFirestore.instance);
}

@riverpod
TripStateMachine tripStateMachine(Ref ref) {
  return TripStateMachine();
}

@riverpod
RequestTrip requestTrip(Ref ref) {
  return RequestTrip(ref.watch(tripRepositoryProvider), ref.watch(tripStateMachineProvider));
}

@riverpod
AcceptTrip acceptTrip(Ref ref) {
  return AcceptTrip(ref.watch(tripRepositoryProvider), ref.watch(tripStateMachineProvider));
}

@riverpod
AdvanceTrip advanceTrip(Ref ref) {
  return AdvanceTrip(ref.watch(tripRepositoryProvider), ref.watch(tripStateMachineProvider));
}

@riverpod
CancelTrip cancelTrip(Ref ref) {
  return CancelTrip(ref.watch(tripRepositoryProvider), ref.watch(tripStateMachineProvider));
}

@riverpod
Stream<(String, TripState)?> watchActiveTrip(Ref ref, String passengerId) {
  return ref.watch(tripRepositoryProvider).watchActiveTrip(passengerId);
}

@riverpod
Stream<(String, TripState)?> watchActiveDriverTrip(Ref ref, String driverId) {
  return ref.watch(tripRepositoryProvider).watchActiveDriverTrip(driverId);
}

@riverpod
Stream<TripState?> watchTrip(Ref ref, String tripId) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchTrip(tripId);
}

@riverpod
Stream<List<(String, TripState)>> watchByStatus(Ref ref, String status) {
  return ref.watch(tripRepositoryProvider).watchByStatus(status);
}
