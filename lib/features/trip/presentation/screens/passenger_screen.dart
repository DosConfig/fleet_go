import 'package:fleet_go/core/di/trip_providers.dart';
import 'package:fleet_go/features/route/domain/entity/route_info.dart';
import 'package:fleet_go/features/route/presentation/providers/route_state_provider.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:fleet_go/features/trip/presentation/providers/passenger_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PassengerScreen extends ConsumerWidget {
  const PassengerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(passengerTripIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('승객')),
      body: tripId == null
          ? Center(child: _CallButton(onPressed: () => _requestTrip(ref, context)))
          : _TripStatusView(tripId: tripId, onReset: () => ref.read(passengerTripIdProvider.notifier).set(null)),
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
        if (state == null) return const Center(child: Text('Trip을 찾을 수 없습니다'));
        return _TripStatusContent(state: state, tripId: tripId, onReset: onReset);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _TripStatusContent extends ConsumerWidget {
  const _TripStatusContent({required this.state, required this.tripId, required this.onReset});

  final TripState state;
  final String tripId;
  final VoidCallback onReset;

  bool get _isTerminal => state is TripCompleted || state is TripCancelled || state is TripFailed;
  bool get _showMap => state is! TripIdle && state is! TripDispatchProposed && !_isTerminal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_showMap) {
      return _StatusPanel(state: state, tripId: tripId, isTerminal: _isTerminal, onReset: onReset);
    }

    // 하드코딩 좌표 — TripState에 좌표 추가 후 교체
    final routeAsync = ref.watch(tripRouteProvider(
      startLat: 37.4979,
      startLng: 127.0276,
      endLat: 37.5547,
      endLng: 126.9707,
    ));

    return Column(
      children: [
        Expanded(
          child: routeAsync.when(
            data: (route) => _PassengerMap(route: route),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('경로 조회 실패: $e')),
          ),
        ),
        _StatusPanel(state: state, tripId: tripId, isTerminal: _isTerminal, onReset: onReset),
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

class _PassengerMap extends StatelessWidget {
  const _PassengerMap({required this.route});
  final RouteInfo route;

  @override
  Widget build(BuildContext context) {
    final coords = route.coordinates;
    if (coords.isEmpty) return const Center(child: Text('경로 없음'));

    final pathCoords = coords.map((c) => NLatLng(c.lat, c.lng)).toList();
    final start = pathCoords.first;
    final end = pathCoords.last;

    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(target: start, zoom: 13),
      ),
      onMapReady: (controller) {
        final path = NPathOverlay(
          id: 'route',
          coords: pathCoords,
          color: Colors.blue,
          width: 4,
        );
        controller.addOverlay(path);

        final pickupMarker = NMarker(id: 'pickup', position: start);
        pickupMarker.setCaption(const NOverlayCaption(text: '출발'));
        controller.addOverlay(pickupMarker);

        final destMarker = NMarker(id: 'destination', position: end);
        destMarker.setCaption(const NOverlayCaption(text: '도착'));
        controller.addOverlay(destMarker);

        // 드라이버 마커는 W4에서 RTDB 실시간 위치 연동 시 추가

        final bounds = NLatLngBounds.from(pathCoords);
        controller.updateCamera(
          NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(48)),
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state, required this.tripId, required this.isTerminal, required this.onReset});

  final TripState state;
  final String tripId;
  final bool isTerminal;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_TripStatusContent._statusLabel(state), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Trip ID: $tripId', style: Theme.of(context).textTheme.bodySmall),
            if (isTerminal) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onReset, child: const Text('새 호출')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
