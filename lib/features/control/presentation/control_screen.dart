import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/fleet_vehicle.dart';
import 'fleet_providers.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  NaverMapController? _mapController;
  // 마커 인스턴스 재사용. clearOverlays 제거의 핵심
  final _markerCache = <String, NMarker>{};

  @override
  void dispose() {
    _markerCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<FleetVehicle>>>(
      fleetSnapshotsProvider,
      (_, next) {
        final controller = _mapController;
        if (controller == null) return;

        final vehicles = next.value;
        if (vehicles == null) return;

        final currentIds = <String>{};

        for (final v in vehicles) {
          currentIds.add(v.vehicleId);
          final existing = _markerCache[v.vehicleId];
          if (existing != null) {
            existing.setPosition(NLatLng(v.lat, v.lng));
          } else {
            final marker = NMarker(
              id: v.vehicleId,
              position: NLatLng(v.lat, v.lng),
            )..setCaption(NOverlayCaption(text: v.vehicleId));
            _markerCache[v.vehicleId] = marker;
            controller.addOverlay(marker);
          }
        }

        // 사라진 차량 제거. mock에선 차량 수 고정이라 실행 안 됨
        final staleIds = _markerCache.keys
            .where((id) => !currentIds.contains(id))
            .toList();
        for (final id in staleIds) {
          controller.deleteOverlay(
            NOverlayInfo(type: NOverlayType.marker, id: id),
          );
          _markerCache.remove(id);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('관제')),
      body: NaverMap(
        options: const NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(37.5665, 126.9780),
            zoom: 14,
          ),
        ),
        onMapReady: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
