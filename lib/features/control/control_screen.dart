import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'vehicle_position.dart';

// mock 데이터, 시뮬레이터 연동 시 provider로 교체
final _mockVehicles = [
  VehiclePosition(vehicleId: 'V-001', lat: 37.5665, lng: 126.9780, heading: 45, speed: 30, timestamp: DateTime.now()),
  VehiclePosition(vehicleId: 'V-002', lat: 37.5700, lng: 126.9820, heading: 120, speed: 25, timestamp: DateTime.now()),
  VehiclePosition(vehicleId: 'V-003', lat: 37.5630, lng: 126.9750, heading: 270, speed: 0, timestamp: DateTime.now()),
];

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          final markers = _mockVehicles.map((v) {
            return NMarker(
              id: v.vehicleId,
              position: NLatLng(v.lat, v.lng),
            )..setCaption(NOverlayCaption(text: v.vehicleId));
          }).toSet();
          controller.addOverlayAll(markers);
        },
      ),
    );
  }
}
