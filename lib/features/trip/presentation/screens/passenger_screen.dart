import 'package:fleet_go/core/di/auth_providers.dart';
import 'package:fleet_go/core/di/location_providers.dart';
import 'package:fleet_go/core/di/trip_providers.dart';
import 'package:fleet_go/features/route/domain/entity/route_info.dart';
import 'package:fleet_go/features/route/presentation/providers/route_state_provider.dart';
import 'package:fleet_go/features/trip/domain/entity/trip_state.dart';
import 'package:fleet_go/features/trip/presentation/providers/passenger_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: 승객 위치 선택 UI 추가 시 제거
const _kDefaultOriginLat = 37.4979;
const _kDefaultOriginLng = 127.0276;
const _kDefaultDestLat = 37.5547;
const _kDefaultDestLng = 126.9707;

class PassengerScreen extends ConsumerWidget {
  const PassengerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeTripAsync = ref.watch(watchActiveTripProvider(user.uid));
    final activeTrip = activeTripAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('승객'),
        leading: activeTrip != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _cancelAndGoBack(ref, context, activeTrip.$1, user.uid),
              )
            : null,
      ),
      body: activeTrip == null
          ? _CallView(onCall: () => _requestTrip(ref, context, user.uid))
          : _TripTrackingView(tripId: activeTrip.$1, state: activeTrip.$2),
    );
  }

  Future<void> _requestTrip(WidgetRef ref, BuildContext context, String passengerId) async {
    if (ref.read(passengerLoadingProvider)) return;
    ref.read(passengerLoadingProvider.notifier).set(true);

    final tripId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await ref.read(requestTripProvider).call(
        tripId: tripId,
        passengerId: passengerId,
        originLat: _kDefaultOriginLat,
        originLng: _kDefaultOriginLng,
        destLat: _kDefaultDestLat,
        destLng: _kDefaultDestLng,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('호출 실패: $e')));
      }
    } finally {
      ref.read(passengerLoadingProvider.notifier).set(false);
    }
  }

  Future<void> _cancelAndGoBack(WidgetRef ref, BuildContext context, String tripId, String passengerId) async {
    try {
      await ref.read(cancelTripProvider).call(tripId: tripId, cancelledBy: passengerId, reason: '승객 취소');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('취소 실패: $e')));
      }
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
              target: const NLatLng(_kDefaultOriginLat, _kDefaultOriginLng),
              zoom: 15,
            ),
          ),
          onMapReady: (controller) {
            final marker = NMarker(id: 'my_location', position: const NLatLng(_kDefaultOriginLat, _kDefaultOriginLng));
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
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.local_taxi),
              label: Text(isLoading ? '호출 중...' : '셔틀 호출'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TripTrackingView extends ConsumerWidget {
  const _TripTrackingView({required this.tripId, required this.state});

  final String tripId;
  final TripState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coords = _extractCoords(state);
    final driverId = _extractDriverId(state);

    final routeAsync = coords != null
        ? ref.watch(
            tripRouteProvider(
              startLat: coords.originLat,
              startLng: coords.originLng,
              endLat: coords.destLat,
              endLng: coords.destLng,
            ),
          )
        : null;

    return Stack(
      children: [
        if (routeAsync != null)
          routeAsync.when(
            data: (route) => _TrackingMap(route: route, driverId: driverId),
            loading: () => _defaultMap(coords),
            error: (_, _) => _defaultMap(coords),
          )
        else
          _defaultMap(null),
        Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: _StatusCard(state: state, tripId: tripId),
          ),
        ),
      ],
    );
  }

  static Widget _defaultMap(_TripCoords? coords) {
    final lat = coords?.originLat ?? _kDefaultOriginLat;
    final lng = coords?.originLng ?? _kDefaultOriginLng;
    return NaverMap(
      options: NaverMapViewOptions(initialCameraPosition: NCameraPosition(target: NLatLng(lat, lng), zoom: 15)),
    );
  }

  static _TripCoords? _extractCoords(TripState state) {
    return switch (state) {
      final TripDispatchProposed s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      final TripAccepted s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      final TripNavigatingToPickup s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      final TripArrivedAtPickup s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      final TripPassengerPickedUp s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      final TripNavigatingToDestination s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      final TripCompleted s => _TripCoords(originLat: s.originLat, originLng: s.originLng, destLat: s.destLat, destLng: s.destLng),
      _ => null,
    };
  }

  static String? _extractDriverId(TripState state) {
    return switch (state) {
      final TripAccepted s => s.driverId,
      final TripNavigatingToPickup s => s.driverId,
      final TripArrivedAtPickup s => s.driverId,
      final TripPassengerPickedUp s => s.driverId,
      final TripNavigatingToDestination s => s.driverId,
      final TripCompleted s => s.driverId,
      _ => null,
    };
  }
}

class _TripCoords {
  const _TripCoords({required this.originLat, required this.originLng, required this.destLat, required this.destLng});
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
}

class _TrackingMap extends ConsumerStatefulWidget {
  const _TrackingMap({required this.route, this.driverId});
  final RouteInfo route;
  final String? driverId;

  @override
  ConsumerState<_TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends ConsumerState<_TrackingMap> {
  NaverMapController? _controller;
  NMarker? _driverMarker;

  @override
  Widget build(BuildContext context) {
    final coords = widget.route.coordinates;

    if (widget.driverId != null) {
      final driverLocation = ref.watch(watchDriverLocationStreamProvider(widget.driverId!)).value;
      if (driverLocation != null && _controller != null) {
        final pos = NLatLng(driverLocation.lat, driverLocation.lng);
        if (_driverMarker == null) {
          _driverMarker = NMarker(id: 'driver', position: pos);
          _driverMarker!.setCaption(const NOverlayCaption(text: '드라이버'));
          _controller!.addOverlay(_driverMarker!);
        } else {
          _driverMarker!.setPosition(pos);
        }
      }
    }

    if (coords.isEmpty) {
      return NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: const NLatLng(_kDefaultOriginLat, _kDefaultOriginLng),
            zoom: 15,
          ),
        ),
        onMapReady: (controller) => _controller = controller,
      );
    }

    final pathCoords = coords.map((c) => NLatLng(c.lat, c.lng)).toList();

    return NaverMap(
      options: NaverMapViewOptions(initialCameraPosition: NCameraPosition(target: pathCoords.first, zoom: 13)),
      onMapReady: (controller) {
        _controller = controller;

        controller.addOverlay(NPathOverlay(id: 'route', coords: pathCoords, color: Theme.of(context).colorScheme.primary, width: 4));

        final pickupMarker = NMarker(id: 'pickup', position: pathCoords.first);
        pickupMarker.setCaption(const NOverlayCaption(text: '출발'));
        controller.addOverlay(pickupMarker);

        final destMarker = NMarker(id: 'destination', position: pathCoords.last);
        destMarker.setCaption(const NOverlayCaption(text: '도착'));
        controller.addOverlay(destMarker);

        final bounds = NLatLngBounds.from(pathCoords);
        controller.updateCamera(NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(48)));
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.tripId});

  final TripState state;
  final String tripId;

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
                Icon(_statusIcon(state), size: 20, color: _statusColor(context, state)),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusLabel(state), style: Theme.of(context).textTheme.titleMedium)),
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
              Text(
                state is TripCompleted ? '운행이 완료되었습니다' : '운행이 종료되었습니다',
                style: Theme.of(context).textTheme.bodySmall,
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

  static Color _statusColor(BuildContext context, TripState state) {
    final cs = Theme.of(context).colorScheme;
    return switch (state) {
      TripDispatchProposed() => cs.tertiary,
      TripAccepted() || TripNavigatingToPickup() || TripArrivedAtPickup() => cs.primary,
      TripPassengerPickedUp() || TripNavigatingToDestination() => cs.primary,
      TripCompleted() => cs.primary,
      TripCancelled() || TripFailed() => cs.error,
      _ => cs.outline,
    };
  }
}

