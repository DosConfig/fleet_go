import 'package:fleet_go/core/di/auth_providers.dart';
import 'package:fleet_go/core/di/trip_providers.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_event.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:fleet_go/features/trip/presentation/providers/driver_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverScreen extends ConsumerWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTripId = ref.watch(driverTripIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('드라이버')),
      body: activeTripId == null
          ? _ProposedList(onAccept: (tripId) => _acceptTrip(ref, context, tripId))
          : _ActiveTripView(tripId: activeTripId, onBack: () => ref.read(driverTripIdProvider.notifier).set(null)),
    );
  }

  Future<void> _acceptTrip(WidgetRef ref, BuildContext context, String tripId) async {
    final user = ref.read(authStateProvider).value;
    final driverId = user?.uid ?? 'unknown';

    try {
      await ref.read(acceptTripProvider).call(tripId: tripId, driverId: driverId);
      ref.read(driverTripIdProvider.notifier).set(tripId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수락 실패: $e')));
      }
    }
  }
}

class _ProposedList extends ConsumerWidget {
  const _ProposedList({required this.onAccept});
  final Future<void> Function(String tripId) onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposedAsync = ref.watch(watchByStatusProvider('dispatchProposed'));
    return proposedAsync.when(
      data: (trips) {
        if (trips.isEmpty) return const Center(child: Text('배차 요청 없음'));
        return ListView.builder(
          itemBuilder: (context, index) {
            final (tripId, state) = trips[index];
            return _ProposedTile(tripId: tripId, state: state, onAccept: () => onAccept(tripId));
          },
          itemCount: trips.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _ProposedTile extends StatelessWidget {
  const _ProposedTile({required this.tripId, required this.state, required this.onAccept});

  final String tripId;
  final TripState state;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Trip: $tripId'),
      subtitle: state is TripDispatchProposed ? Text('요청: ${(state as TripDispatchProposed).proposedAt}') : null,
      trailing: FilledButton(onPressed: onAccept, child: const Text('수락')),
    );
  }
}

class _ActiveTripView extends ConsumerWidget {
  const _ActiveTripView({required this.tripId, required this.onBack});
  final String tripId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(watchTripProvider(tripId));
    return tripAsync.when(
      data: (state) {
        if (state == null) return const Center(child: Text('Trip을 찾을 수 없습니다'));
        return _ActiveTripContent(
          tripId: tripId,
          state: state,
          onBack: onBack,
          onAdvance: (event) async {
            try {
              await ref.read(advanceTripProvider).call(tripId: tripId, event: event);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('전이 실패: $e')));
              }
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _ActiveTripContent extends StatelessWidget {
  const _ActiveTripContent({required this.tripId, required this.state, required this.onBack, required this.onAdvance});

  final String tripId;
  final TripState state;
  final VoidCallback onBack;
  final void Function(TripEvent event) onAdvance;

  bool get _isTerminal => state is TripCompleted || state is TripCancelled || state is TripFailed;

  @override
  Widget build(BuildContext context) {
    final nextEvent = _nextEvent(state);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_statusLabel(state), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Trip ID: $tripId', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          if (nextEvent != null)
            FilledButton(onPressed: () => onAdvance(nextEvent), child: Text(_eventLabel(nextEvent))),
          if (_isTerminal) FilledButton(onPressed: onBack, child: const Text('배차 목록으로')),
        ],
      ),
    );
  }

  static TripEvent? _nextEvent(TripState state) {
    return switch (state) {
      TripAccepted() => TripEvent.startNavToPickup,
      TripNavigatingToPickup() => TripEvent.arriveAtPickup,
      TripArrivedAtPickup() => TripEvent.pickUpPassenger,
      TripPassengerPickedUp() => TripEvent.startNavToDestination,
      TripNavigatingToDestination() => TripEvent.complete,
      _ => null,
    };
  }

  static String _statusLabel(TripState state) {
    return switch (state) {
      TripIdle() => '대기 중',
      TripDispatchProposed() => '배차 요청 중',
      TripAccepted() => '배차 수락됨',
      TripNavigatingToPickup() => '픽업지로 이동 중',
      TripArrivedAtPickup() => '픽업지 도착',
      TripPassengerPickedUp() => '승객 탑승',
      TripNavigatingToDestination() => '목적지로 이동 중',
      TripCompleted() => '운행 완료',
      TripCancelled() => '취소됨',
      TripFailed() => '오류 발생',
    };
  }

  static String _eventLabel(TripEvent event) {
    return switch (event) {
      TripEvent.startNavToPickup => '픽업지로 출발',
      TripEvent.arriveAtPickup => '픽업지 도착',
      TripEvent.pickUpPassenger => '승객 탑승',
      TripEvent.startNavToDestination => '목적지로 출발',
      TripEvent.complete => '운행 완료',
      _ => event.name,
    };
  }
}
