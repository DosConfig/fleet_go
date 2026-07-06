import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/trip/data/repository/trip_repository_impl.dart';
import '../../features/trip/domain/repository/trip_repository.dart';
import '../../features/trip/domain/usecase/accept_trip.dart';
import '../../features/trip/domain/usecase/advance_trip.dart';
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
