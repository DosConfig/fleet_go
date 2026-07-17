import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

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

  // 차량 ID는 불변이므로 매 틱 재생성하지 않고 한 번만 만들어 재사용
  late final List<String> _ids = List.generate(
    vehicleCount,
    (i) => 'V-${(i + 1).toString().padLeft(5, '0')}',
    growable: false,
  );

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
      // isolate 경계 프로토콜: Map 리스트가 아닌 Float64List(타입드 데이터).
      // Map 10만 개는 틱마다 구조 순회 직렬화로 메인 스레드를 수십 ms
      // 태우지만, 타입드 데이터는 버퍼째로 저비용 전송된다.
      // 레이아웃: [lat, lng, heading, speed] × vehicleCount
      if (message is Float64List) {
        final now = DateTime.now();
        final vehicles = List<FleetVehicle>.generate(
          vehicleCount,
          (i) => FleetVehicle(
            vehicleId: _ids[i],
            lat: message[i * 4],
            lng: message[i * 4 + 1],
            heading: message[i * 4 + 2],
            speed: message[i * 4 + 3],
            capturedAt: now,
          ),
          growable: false,
        );
        _controller.add(vehicles);
      }
    });
  }

  static void _isolateEntry(_IsolateConfig config) {
    final random = Random(42);
    final n = config.vehicleCount;

    // 도심 ±0.15°(약 33km, 서울 전역 규모)로 분산 배치.
    // 좁게 몰아두면 전 차량이 항상 화면 안이라 컬링/클러스터가 발동하지
    // 않아 렌더 전략 B와 C의 차이를 측정할 수 없다.
    // 레이아웃: [lat, lng, heading, speed] × n
    final data = Float64List(n * 4);
    for (var i = 0; i < n; i++) {
      data[i * 4] = 37.5665 + (random.nextDouble() - 0.5) * 0.3;
      data[i * 4 + 1] = 126.9780 + (random.nextDouble() - 0.5) * 0.3;
      data[i * 4 + 2] = random.nextDouble() * 360; // heading
      data[i * 4 + 3] = random.nextDouble() * 60; // speed
    }

    Timer.periodic(Duration(milliseconds: config.tickIntervalMs), (_) {
      for (var i = 0; i < n; i++) {
        data[i * 4] += (random.nextDouble() - 0.5) * 0.001;
        data[i * 4 + 1] += (random.nextDouble() - 0.5) * 0.001;
      }
      // 수신 측과 버퍼를 공유하지 않도록 복사본 전송 (타입드 데이터라 저비용)
      config.sendPort.send(Float64List.fromList(data));
    });
  }

  @override
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _controller.close();
  }
}
