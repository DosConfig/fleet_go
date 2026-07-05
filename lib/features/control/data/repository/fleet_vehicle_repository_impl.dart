import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import '../../domain/entity/fleet_vehicle.dart';
import '../../domain/repository/fleet_vehicle_repository.dart';

class _IsolateConfig {
  _IsolateConfig({required this.sendPort, required this.vehicleCount, required this.tickIntervalMs});

  final SendPort sendPort;
  final int vehicleCount;
  final int tickIntervalMs;
}

class FleetVehicleRepositoryImpl implements FleetVehicleRepository {
  FleetVehicleRepositoryImpl({this.vehicleCount = 3, this.tickInterval = const Duration(milliseconds: 500)});

  final int vehicleCount;
  final Duration tickInterval;
  final _controller = StreamController<List<FleetVehicle>>.broadcast();
  Isolate? _isolate;
  ReceivePort? _receivePort;

  @override
  Stream<List<FleetVehicle>> watch() {
    if (_isolate == null) _startIsolate();
    return _controller.stream;
  }

  Future<void> _startIsolate() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateConfig(
        sendPort: _receivePort!.sendPort,
        vehicleCount: vehicleCount,
        tickIntervalMs: tickInterval.inMilliseconds,
      ),
    );
    _receivePort!.listen((message) {
      if (message is List<Map<String, dynamic>>) {
        final vehicles = message
            .map(
              (m) => FleetVehicle(
                vehicleId: m['vehicleId'] as String,
                lat: m['lat'] as double,
                lng: m['lng'] as double,
                heading: m['heading'] as double,
                speed: m['speed'] as double,
                capturedAt: DateTime.fromMillisecondsSinceEpoch(m['capturedAt'] as int),
              ),
            )
            .toList();
        _controller.add(vehicles);
      }
    });
  }

  static void _isolateEntry(_IsolateConfig config) {
    final random = Random(42);
    final vehicles = List.generate(config.vehicleCount, (i) {
      return {
        'vehicleId': 'V-${(i + 1).toString().padLeft(3, '0')}',
        'lat': 37.5665 + (random.nextDouble() - 0.5) * 0.04,
        'lng': 126.9780 + (random.nextDouble() - 0.5) * 0.04,
        'heading': random.nextDouble() * 360,
        'speed': random.nextDouble() * 60,
        'capturedAt': DateTime.now().millisecondsSinceEpoch,
      };
    });

    Timer.periodic(Duration(milliseconds: config.tickIntervalMs), (_) {
      for (final v in vehicles) {
        v['lat'] = (v['lat'] as double) + (random.nextDouble() - 0.5) * 0.001;
        v['lng'] = (v['lng'] as double) + (random.nextDouble() - 0.5) * 0.001;
        v['capturedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      config.sendPort.send(List<Map<String, dynamic>>.from(vehicles.map((v) => Map<String, dynamic>.from(v))));
    });
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _controller.close();
  }
}
