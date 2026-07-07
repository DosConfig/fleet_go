import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/datasource/gps_datasource.dart';

class DeviceGpsDatasource implements GpsDatasource {
  StreamSubscription<Position>? _subscription;
  final _controller = StreamController<({double lat, double lng, double heading, double speed})>.broadcast();

  @override
  Stream<({double lat, double lng, double heading, double speed})> watchPosition() {
    if (_subscription == null) _startListening();
    return _controller.stream;
  }

  Future<void> _startListening() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((position) {
      _controller.add((
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
      ));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
