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

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<FleetVehicle>>>(
      fleetSnapshotsProvider,
      (_, next) {
        final controller = _mapController;
        if (controller == null) return;

        final vehicles = next.value;
        if (vehicles == null) return;

        final markers = vehicles.map((v) {
          return NMarker(
            id: v.vehicleId,
            position: NLatLng(v.lat, v.lng),
          )..setCaption(NOverlayCaption(text: v.vehicleId));
        }).toSet();

        controller.clearOverlays();
        controller.addOverlayAll(markers);
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
