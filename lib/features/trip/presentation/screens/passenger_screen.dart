import 'package:fleet_go/core/di/location_providers.dart';
import 'package:fleet_go/core/di/trip_providers.dart';
import 'package:fleet_go/features/route/domain/entity/route_info.dart';
import 'package:fleet_go/features/route/presentation/providers/route_state_provider.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:fleet_go/features/trip/presentation/providers/passenger_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 하드코딩 좌표 — TripState에 좌표 추가 후 교체
const _kPickupLat = 37.4979;
const _kPickupLng = 127.0276;
const _kDestLat = 37.5547;
const _kDestLng = 126.9707;

class PassengerScreen extends ConsumerWidget {
  const PassengerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(passengerTripIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('승객')),
      body: tripId == null
          ? _CallView(onCall: () => _requestTrip(ref, context))
          : _TripTrackingView(tripId: tripId, onReset: () => ref.read(passengerTripIdProvider.notifier).set(null)),
    );
  }

  Future<void> _requestTrip(WidgetRef ref, BuildContext context) async {
    if (ref.read(passengerLoadingProvider)) return;
    ref.read(passengerLoadingProvider.notifier).set(true);

    final tripId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await ref.read(requestTripProvider).call(tripId: tripId);
      ref.read(passengerTripIdProvider.notifier).set(tripId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('호출 실패: $e')));
      }
    } finally {
      ref.read(passengerLoadingProvider.notifier).set(false);
    }
  }
}

class _CallView extends ConsumerWidget {
  const _CallView({required this.onCall});
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(passengerLoadingProvider);

    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: const NLatLng(_kPickupLat, _kPickupLng),
              zoom: 15,
            ),
          ),
          onMapReady: (controller) {
            final marker = NMarker(
              id: 'my_location',
              position: const NLatLng(_kPickupLat, _kPickupLng),
            );
            marker.setCaption(const NOverlayCaption(text: '현재 위치'));
            controller.addOverlay(marker);
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onCall,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.local_taxi),
              label: Text(isLoading ? '호출 중...' : '셔틀 호출'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TripTrackingView extends ConsumerWidget {
  const _TripTrackingView({required this.tripId, required this.onReset});

  final String tripId;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(watchTripProvider(tripId));
    final routeAsync = ref.watch(tripRouteProvider(
      startLat: _kPickupLat,
      startLng: _kPickupLng,
      endLat: _kDestLat,
      endLng: _kDestLng,
    ));

    final driverId = _extractDriverId(tripAsync.value);

    return Stack(
      children: [
        routeAsync.when(
          data: (route) => _TrackingMap(route: route, driverId: driverId),
          loading: () => NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: const NLatLng(_kPickupLat, _kPickupLng),
                zoom: 15,
              ),
            ),
          ),
          error: (_, _) => NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: const NLatLng(_kPickupLat, _kPickupLng),
                zoom: 15,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: tripAsync.when(
              data: (state) {
                if (state == null) return const SizedBox.shrink();
                return _StatusCard(state: state, tripId: tripId, onReset: onReset);
              },
              loading: () => _StatusCardLoading(),
              error: (e, _) => _StatusCardError(error: e.toString()),
            ),
          ),
        ),
      ],
    );
  }

  static String? _extractDriverId(TripState? state) {
    return switch (state) {
      TripAccepted(:final driverId) => driverId,
      TripNavigatingToPickup(:final driverId) => driverId,
      TripArrivedAtPickup(:final driverId) => driverId,
      TripPassengerPickedUp(:final driverId) => driverId,
      TripNavigatingToDestination(:final driverId) => driverId,
      TripCompleted(:final driverId) => driverId,
      _ => null,
    };
  }
}

class _TrackingMap extends ConsumerWidget {
  const _TrackingMap({required this.route, this.driverId});
  final RouteInfo route;
  final String? driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coords = route.coordinates;
    final driverLocation = driverId != null
        ? ref.watch(watchDriverLocationStreamProvider(driverId!)).value
        : null;

    if (coords.isEmpty) {
      return NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: const NLatLng(_kPickupLat, _kPickupLng),
            zoom: 15,
          ),
        ),
      );
    }

    final pathCoords = coords.map((c) => NLatLng(c.lat, c.lng)).toList();

    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(target: pathCoords.first, zoom: 13),
      ),
      onMapReady: (controller) {
        controller.addOverlay(NPathOverlay(
          id: 'route',
          coords: pathCoords,
          color: Colors.blue,
          width: 4,
        ));

        final pickupMarker = NMarker(id: 'pickup', position: pathCoords.first);
        pickupMarker.setCaption(const NOverlayCaption(text: '출발'));
        controller.addOverlay(pickupMarker);

        final destMarker = NMarker(id: 'destination', position: pathCoords.last);
        destMarker.setCaption(const NOverlayCaption(text: '도착'));
        controller.addOverlay(destMarker);

        if (driverLocation != null) {
          final driverMarker = NMarker(
            id: 'driver',
            position: NLatLng(driverLocation.lat, driverLocation.lng),
          );
          driverMarker.setCaption(const NOverlayCaption(text: '드라이버'));
          controller.addOverlay(driverMarker);
        }

        final bounds = NLatLngBounds.from(pathCoords);
        controller.updateCamera(
          NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(48)),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.tripId, required this.onReset});

  final TripState state;
  final String tripId;
  final VoidCallback onReset;

  bool get _isTerminal => state is TripCompleted || state is TripCancelled || state is TripFailed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_statusIcon(state), size: 20, color: _statusColor(state)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_statusLabel(state), style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            if (state is TripDispatchProposed) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text('드라이버를 찾고 있습니다', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_isTerminal) ...[
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

  static IconData _statusIcon(TripState state) {
    return switch (state) {
      TripDispatchProposed() => Icons.search,
      TripAccepted() => Icons.person_pin,
      TripNavigatingToPickup() => Icons.directions_car,
      TripArrivedAtPickup() => Icons.place,
      TripPassengerPickedUp() => Icons.airline_seat_recline_normal,
      TripNavigatingToDestination() => Icons.navigation,
      TripCompleted() => Icons.check_circle,
      TripCancelled() => Icons.cancel,
      TripFailed() => Icons.error,
      _ => Icons.info,
    };
  }

  static Color _statusColor(TripState state) {
    return switch (state) {
      TripDispatchProposed() => Colors.orange,
      TripAccepted() || TripNavigatingToPickup() || TripArrivedAtPickup() => Colors.blue,
      TripPassengerPickedUp() || TripNavigatingToDestination() => Colors.green,
      TripCompleted() => Colors.green,
      TripCancelled() || TripFailed() => Colors.red,
      _ => Colors.grey,
    };
  }
}

class _StatusCardLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('상태 확인 중...'),
          ],
        ),
      ),
    );
  }
}

class _StatusCardError extends StatelessWidget {
  const _StatusCardError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('오류: $error', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
      ),
    );
  }
}
