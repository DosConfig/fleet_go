import 'package:fleet_go/core/di/trip_providers.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:fleet_go/features/trip/presentation/providers/passenger_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PassengerScreen extends ConsumerWidget {
  const PassengerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(passengerTripIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("승객")),
      body: Center(
        child: tripId == null
            ? _CallButton(onPressed: () => _requestTrip(ref, context))
            : _TripStatusView(tripId: tripId, onReset: () => ref.read(passengerTripIdProvider.notifier).set(null)),
      ),
    );
  }

  Future<void> _requestTrip(WidgetRef ref, BuildContext context) async {
    final tripId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await ref.read(requestTripProvider).call(tripId: tripId);
      ref.read(passengerTripIdProvider.notifier).set(tripId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('호출 실패: $e')));
      }
    }
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.local_taxi), label: const Text('셔틀 호출'));
  }
}

class _TripStatusView extends ConsumerWidget {
  const _TripStatusView({required this.tripId, required this.onReset});

  final String tripId;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(watchTripProvider(tripId));
    return tripAsync.when(
      data: (state) {
        if (state == null) return const Text('Trip을 찾을 수 없습니다');
        return _TripStatusContent(state: state, tripId: tripId, onReset: onReset);
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('오류: $e'),
    );
  }
}

class _TripStatusContent extends StatelessWidget {
  const _TripStatusContent({required this.state, required this.tripId, required this.onReset});

  final TripState state;
  final String tripId;
  final VoidCallback onReset;

  bool get _isTerminal => state is TripCompleted || state is TripCancelled || state is TripFailed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_statusLabel(state), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Trip ID: $tripId', style: Theme.of(context).textTheme.bodySmall),
        if (_isTerminal) ...[const SizedBox(height: 24), FilledButton(onPressed: onReset, child: const Text('새 호출'))],
      ],
    );
  }

  static String _statusLabel(TripState state) {
    return switch (state) {
      TripIdle() => '대기 중',
      TripDispatchProposed() => '배차 요청 중...',
      TripAccepted() => '드라이버 배정됨',
      TripNavigatingToPickup() => '드라이버 이동 중',
      TripArrivedAtPickup() => '드라이버 도착',
      TripPassengerPickedUp() => '탑승 완료',
      TripNavigatingToDestination() => '목적지 이동 중',
      TripCompleted() => '운행 완료',
      TripCancelled() => '취소됨',
      TripFailed() => '오류 발생',
    };
  }
}
