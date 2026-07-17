import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/fleet_vehicle_providers.dart';
import '../../../core/perf/frame_logger.dart';
import '../domain/entity/fleet_vehicle.dart';
import 'fleet_providers.dart';

/// 렌더 전략 3단계. AppBar 버튼으로 순환하며 [PERF] 로그로 비교 측정한다.
enum RenderMode {
  /// A. 이전 방식 재현: 매 틱 전체 삭제(clearOverlays) 후 전체 재생성
  rebuildAll('A_rebuildAll', '전체 재생성', Icons.delete_sweep),

  /// B. 마커 캐시 + setPosition diff (컬링/클러스터/이동 스킵 없음)
  cacheDiff('B_cacheDiff', '캐시+diff', Icons.cached),

  /// C. B + viewport 컬링 + 픽셀 미만 이동 스킵 + 줌아웃 클러스터
  optimized('C_optimized', '컬링+클러스터', Icons.filter_alt);

  const RenderMode(this.label, this.title, this.icon);

  final String label;
  final String title;
  final IconData icon;
}

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  NaverMapController? _mapController;

  // 개별 차량 마커 캐시. 인스턴스 재사용으로 매 틱 생성/제거 제거
  final _markerCache = <String, NMarker>{};

  // 마지막으로 마커에 반영한 위치. 픽셀 미만 이동 스킵 판단용
  final _lastApplied = <String, NLatLng>{};

  // 클러스터 마커 캐시. key = 그리드 셀 좌표
  final _clusterCache = <String, NMarker>{};

  // 화면 영역(여유 30% 확장)과 줌. 카메라가 멈췄을 때만 갱신해서
  // 매 틱마다 bounds를 묻는 채널 호출이 생기지 않게 한다
  NLatLngBounds? _visibleBounds;
  double _zoom = 14;

  // 이 줌 미만에서는 개별 마커 대신 클러스터로 표시
  static const _clusterZoomThreshold = 13.0;

  // 측정 재현성을 위한 고정 카메라 기준점 (줌 프리셋 버튼용)
  static const _center = NLatLng(37.5665, 126.9780);

  // 클러스터 그리드 셀의 화면상 크기(px)
  static const _clusterCellPx = 80.0;

  // 카메라 이동 직후 컬링/클러스터를 다시 적용하기 위한 마지막 스냅샷
  List<FleetVehicle> _lastVehicles = const [];

  // 성능 비교용 렌더 전략 (A: 전체 재생성 / B: 캐시+diff / C: 컬링+클러스터)
  RenderMode _mode = RenderMode.optimized;

  // 측정 로그 라벨: 모드 + 현재 줌 (예: C_optimized@z12)
  String get _modeLabel => '${_mode.label}@z${_zoom.toStringAsFixed(0)}';

  // 모드 전환 중 틱 reconcile 차단 플래그.
  // clearOverlays 완료 전에 reconcile이 끼어들면 캐시와 네이티브
  // 오버레이 상태가 어긋나 '이미 삭제된 오버레이' assert가 터진다
  bool _resetting = false;

  Future<void> _setMode(RenderMode mode) async {
    // 조건이 바뀌므로 진행 중이던 측정은 정지 (누적 방지)
    FrameLogger.stop();
    setState(() => _mode = mode);
    _resetting = true;
    try {
      _markerCache.clear();
      _clusterCache.clear();
      _lastApplied.clear();
      final controller = _mapController;
      if (controller != null) {
        await controller.clearOverlays(); // 완료를 기다린 뒤 다시 그린다
      }
    } finally {
      _resetting = false;
    }
    _reconcile(_lastVehicles);
  }

  // 손 드래그 없이 동일 조건을 재현하기 위한 줌 프리셋.
  // 카메라를 고정 기준점+지정 줌으로 이동시킨다.
  Future<void> _applyZoomPreset(double zoom) async {
    final controller = _mapController;
    if (controller == null) return;
    // 조건이 바뀌므로 진행 중이던 측정은 정지 (누적 방지)
    FrameLogger.stop();
    setState(() {});
    await controller.updateCamera(
      NCameraUpdate.withParams(target: _center, zoom: zoom),
    );
    await _refreshCamera();
  }

  // 측정 시작/정지 토글. 시작 시점 이전 프레임은 절대 포함되지 않는다
  void _toggleMeasure() {
    if (FrameLogger.isActive) {
      FrameLogger.stop();
    } else {
      FrameLogger.start(label: _modeLabel);
    }
    setState(() {});
  }

  // ── 자동 벤치마크 러너 ──────────────────────────────────────
  //
  // 차량 규모별로 렌더 전략 × 줌 조건을 순서대로 재현하며 측정한다.
  // 사람 손이 개입하지 않으므로 조건이 항상 동일하게 재현된다.
  // 종료 시 [BENCH] 블록으로 전체 결과를 한 번에 출력한다.

  bool _benchRunning = false;
  String _benchStatus = '';

  // 관제 진입 시 자동 실행 여부. 일반 데모 때 방해되면 false로
  static const _autoStartBenchmark = true;

  // 측정할 차량 규모. 수천~십만 대 검증용
  static const _benchCounts = [1000, 5000, 10000, 100000];

  // 조건 변경 후 안정화 대기 / 조건당 측정 시간(5초 윈도우 2개)
  static const _benchSettle = Duration(seconds: 4);
  static const _benchMeasure = Duration(seconds: 12);

  // 조기 실패 판정: 프레임 1개가 틱 간격(500ms)을 넘으면
  // 갱신이 갱신 주기를 따라잡지 못하는 상태 = 측정 지속 무의미
  static const _failFrameMs = 500.0;

  Future<void> _runBenchmark() async {
    if (_benchRunning) return;
    setState(() => _benchRunning = true);
    final report = <String>[];

    var stepNo = 0;
    // A(전체 재생성)는 1,000대에서만: 줌 무관 ~250ms는 이미 확인됐고,
    // 만 대 이상 전체 재생성은 틱(500ms)보다 재생성이 오래 걸려 측정이 무의미.
    // B(캐시+diff)는 10,000대에서 프레임 1.19s로 붕괴가 확인됐으므로
    // 100,000대는 상한 설계(C)만 측정한다
    final totalSteps = _benchCounts.fold<int>(
      0,
      (sum, c) => sum + (c == 1000 ? 5 : (c <= 10000 ? 4 : 3)),
    );

    for (final count in _benchCounts) {
      if (!mounted) return;
      ref.read(mockFleetSizeProvider.notifier).set(count);
      await Future<void>.delayed(_benchSettle); // 새 isolate 데이터 안정화

      final steps = <(RenderMode, double)>[
        if (count == 1000) (RenderMode.rebuildAll, 14),
        if (count <= 10000) (RenderMode.cacheDiff, 14),
        (RenderMode.optimized, 14),
        // C의 최악 케이스: 클러스터 임계(13) 직전 = 개별 마커 모드인데
        // viewport는 최대. 가시 마커 수가 컬링만으로 감당해야 하는 상한
        (RenderMode.optimized, 13.2),
        (RenderMode.optimized, 12),
      ];

      for (final (mode, zoom) in steps) {
        if (!mounted) return;
        stepNo++;
        final stepName = '${mode.label}@z${zoom.toInt()} ($count대)';
        setState(() => _benchStatus = '$stepNo/$totalSteps $stepName');

        await _setMode(mode);
        await _applyZoomPreset(zoom);
        await Future<void>.delayed(_benchSettle);

        FrameLogger.takeSessionLines(); // 이전 스텝 잔여 라인 폐기
        FrameLogger.start(label: '${mode.label}@z${zoom.toInt()}#$count');

        // 만 대 규모 B는 프레임이 초 단위로 늘어져 윈도우가 드물게
        // 나오므로 측정 시간을 늘려 최소 2개 윈도우를 확보한다.
        // 단, 1초마다 실패 판정을 확인해 무너진 조건은 조기 중단한다
        final measure = count >= 10000 ? _benchMeasure * 2 : _benchMeasure;
        var failed = false;
        final elapsed = Stopwatch()..start();
        while (elapsed.elapsed < measure) {
          await Future<void>.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          if (FrameLogger.worstSinceStart > _failFrameMs) {
            failed = true;
            break;
          }
        }
        final worst = FrameLogger.worstSinceStart;
        if (failed) FrameLogger.forceFlush(); // 미완성 윈도우도 증거로 남김
        FrameLogger.stop();

        report.add(
          failed
              ? '─ $stepName  ✗ FAIL — 프레임 ${worst.toStringAsFixed(0)}ms > '
                  '${_failFrameMs.toInt()}ms(틱 간격), 조기 중단'
              : '─ $stepName',
        );
        report.addAll(FrameLogger.takeSessionLines());
      }
    }

    debugPrint('[BENCH] ══════ 자동 벤치마크 결과 ══════');
    for (final line in report) {
      debugPrint('[BENCH] $line');
    }
    debugPrint('[BENCH] ══════ 끝 ══════');

    if (mounted) {
      setState(() {
        _benchRunning = false;
        _benchStatus = '';
      });
    }
  }

  @override
  void dispose() {
    _markerCache.clear();
    _clusterCache.clear();
    _lastApplied.clear();
    super.dispose();
  }

  Future<void> _refreshCamera() async {
    final controller = _mapController;
    if (controller == null) return;
    final pos = await controller.getCameraPosition();
    final bounds = await controller.getContentBounds();
    _zoom = pos.zoom;
    _visibleBounds = _expand(bounds, 0.3);
    // 화면이 바뀌었으니 같은 데이터로 컬링/클러스터를 다시 적용
    _reconcile(_lastVehicles);
  }

  // 경계에서 마커가 뚝뚝 사라지지 않도록 화면 영역을 비율만큼 넓혀서 사용
  NLatLngBounds _expand(NLatLngBounds b, double ratio) {
    final latPad = (b.northEast.latitude - b.southWest.latitude) * ratio;
    final lngPad = (b.northEast.longitude - b.southWest.longitude) * ratio;
    return NLatLngBounds(
      southWest: NLatLng(
        b.southWest.latitude - latPad,
        b.southWest.longitude - lngPad,
      ),
      northEast: NLatLng(
        b.northEast.latitude + latPad,
        b.northEast.longitude + lngPad,
      ),
    );
  }

  bool _inBounds(double lat, double lng) {
    if (_mode != RenderMode.optimized) return true; // A/B 모드는 컬링 없음
    final b = _visibleBounds;
    if (b == null) return true; // 첫 bounds를 받기 전에는 전부 표시
    return lat >= b.southWest.latitude &&
        lat <= b.northEast.latitude &&
        lng >= b.southWest.longitude &&
        lng <= b.northEast.longitude;
  }

  // 현재 줌에서 1픽셀이 몇 미터인지 (웹 메르카토르 근사)
  double get _metersPerPixel =>
      156543.03392 * math.cos(37.5665 * math.pi / 180) / math.pow(2, _zoom);

  // 화면상 1.5픽셀 미만의 이동은 그려도 차이가 없으므로 스킵
  bool _movedEnough(NLatLng last, double lat, double lng) {
    const mPerDegLat = 111320.0;
    final dLat = (lat - last.latitude) * mPerDegLat;
    final dLng =
        (lng - last.longitude) * mPerDegLat * math.cos(lat * math.pi / 180);
    final distSq = dLat * dLat + dLng * dLng;
    final threshold = _metersPerPixel * 1.5;
    return distSq >= threshold * threshold;
  }

  // 이미 삭제된 오버레이를 다시 지우려는 assert 방지용 안전 삭제.
  // 대량(만 단위) 갱신에선 reconcile이 틱보다 오래 걸려 콜백이 밀리고,
  // 그 사이 네이티브 상태가 먼저 바뀌어 있을 수 있다
  void _safeDelete(NaverMapController controller, String id) {
    controller
        .deleteOverlay(NOverlayInfo(type: NOverlayType.marker, id: id))
        .catchError((_) {});
  }

  void _reconcile(List<FleetVehicle> vehicles) {
    final controller = _mapController;
    if (controller == null) return;
    _lastVehicles = vehicles;
    if (_resetting) return; // 모드 전환 중엔 상태가 어긋나므로 스킵

    switch (_mode) {
      case RenderMode.rebuildAll:
        _reconcileRebuildAll(controller, vehicles);
      case RenderMode.cacheDiff:
        _reconcileIndividual(controller, vehicles);
      case RenderMode.optimized:
        if (_zoom < _clusterZoomThreshold) {
          _reconcileClusters(controller, vehicles);
        } else {
          _reconcileIndividual(controller, vehicles);
        }
    }
  }

  // ── A. 전체 재생성 모드 (이전 방식 재현, 비교 기준선) ────────────
  //
  // 커밋 83fe5c6 이전의 접근: 매 틱 clearOverlays로 전부 지우고
  // 차량 수만큼 NMarker를 새로 만들어 다시 올린다. 갱신 주기마다
  // 네이티브 오버레이 객체 생성/제거가 차량 수만큼 반복되는 비용을 측정한다.

  void _reconcileRebuildAll(
    NaverMapController controller,
    List<FleetVehicle> vehicles,
  ) {
    _markerCache.clear();
    _clusterCache.clear();
    _lastApplied.clear();
    controller.clearOverlays();
    for (final v in vehicles) {
      controller.addOverlay(
        NMarker(id: v.vehicleId, position: NLatLng(v.lat, v.lng))
          ..setCaption(NOverlayCaption(text: v.vehicleId)),
      );
    }
    FrameLogger.context = 'rebuilt=${vehicles.length}/${vehicles.length}';
  }

  // ── 개별 마커 모드 (줌 인 상태) ──────────────────────────────

  void _reconcileIndividual(
    NaverMapController controller,
    List<FleetVehicle> vehicles,
  ) {
    // 클러스터 모드에서 넘어왔다면 클러스터 마커 정리
    _clearCache(controller, _clusterCache);

    final dataIds = <String>{};

    for (final v in vehicles) {
      dataIds.add(v.vehicleId);
      final existing = _markerCache[v.vehicleId];
      final visible = _inBounds(v.lat, v.lng);

      if (!visible) {
        // 화면 밖 차량은 마커를 유지하지도 갱신하지도 않는다.
        // 작업량을 차량 수가 아니라 화면에 보이는 수에 종속시키는 것이 목적
        if (existing != null) {
          _safeDelete(controller, v.vehicleId);
          _markerCache.remove(v.vehicleId);
          _lastApplied.remove(v.vehicleId);
        }
        continue;
      }

      if (existing != null) {
        final last = _lastApplied[v.vehicleId];
        // 픽셀 미만 이동은 setPosition 호출 자체를 생략
        // (B 모드는 순수 캐시+diff 비교를 위해 스킵 비활성)
        if (_mode != RenderMode.optimized ||
            last == null ||
            _movedEnough(last, v.lat, v.lng)) {
          final p = NLatLng(v.lat, v.lng);
          existing.setPosition(p);
          _lastApplied[v.vehicleId] = p;
        }
      } else {
        final p = NLatLng(v.lat, v.lng);
        final marker = NMarker(id: v.vehicleId, position: p)
          ..setCaption(NOverlayCaption(text: v.vehicleId));
        _markerCache[v.vehicleId] = marker;
        _lastApplied[v.vehicleId] = p;
        controller.addOverlay(marker);
      }
    }

    // 데이터에서 사라진 차량 제거
    final staleIds =
        _markerCache.keys.where((id) => !dataIds.contains(id)).toList();
    for (final id in staleIds) {
      _safeDelete(controller, id);
      _markerCache.remove(id);
      _lastApplied.remove(id);
    }

    // 화면에 실재하는 마커 수 / 전체 차량 수 (컬링 효과의 직접 지표)
    FrameLogger.context = 'markers=${_markerCache.length}/${vehicles.length}';
  }

  // ── 클러스터 모드 (줌 아웃 상태) ─────────────────────────────
  //
  // 화면을 _clusterCellPx 크기의 그리드로 잘라 셀 안의 차량을 하나의
  // 마커로 묶는다. 그리는 개수가 차량 수가 아니라 셀 수에 종속되므로
  // 줌 아웃으로 전체 차량이 보이는 상황에서도 부하가 제한된다.

  void _reconcileClusters(
    NaverMapController controller,
    List<FleetVehicle> vehicles,
  ) {
    // 개별 모드에서 넘어왔다면 개별 마커 정리
    _clearCache(controller, _markerCache);
    _lastApplied.clear();

    // 셀 크기(도 단위): 화면 px 크기를 위경도로 환산
    final cellLat = _metersPerPixel * _clusterCellPx / 111320.0;
    final cellLng = cellLat / math.cos(37.5665 * math.pi / 180);

    // 셀별 집계 (합산 후 중심점 = 셀 내 차량들의 평균 위치)
    final sums = <String, List<double>>{}; // key -> [latSum, lngSum, count]
    for (final v in vehicles) {
      if (!_inBounds(v.lat, v.lng)) continue;
      final key =
          '${(v.lat / cellLat).floor()}_${(v.lng / cellLng).floor()}';
      final s = sums.putIfAbsent(key, () => [0, 0, 0]);
      s[0] += v.lat;
      s[1] += v.lng;
      s[2] += 1;
    }

    final liveKeys = <String>{};
    sums.forEach((key, s) {
      liveKeys.add(key);
      final count = s[2].toInt();
      final centroid = NLatLng(s[0] / count, s[1] / count);
      final clusterId = 'cluster_$key';

      final existing = _clusterCache[key];
      if (existing != null) {
        // 셀은 고정 그리드라 중심점 이동은 셀 내 분포 변화뿐 - 위치와 개수만 갱신
        existing.setPosition(centroid);
        existing.setCaption(NOverlayCaption(text: '$count대'));
      } else {
        final marker = NMarker(id: clusterId, position: centroid)
          ..setCaption(NOverlayCaption(text: '$count대'));
        _clusterCache[key] = marker;
        controller.addOverlay(marker);
      }
    });

    // 비워진 셀의 클러스터 마커 제거
    final staleKeys =
        _clusterCache.keys.where((k) => !liveKeys.contains(k)).toList();
    for (final k in staleKeys) {
      _safeDelete(controller, 'cluster_$k');
      _clusterCache.remove(k);
    }

    // 클러스터 셀 수 / 전체 차량 수 (그리는 개수가 셀 수에 종속되는 증거)
    FrameLogger.context = 'clusters=${_clusterCache.length}/${vehicles.length}';
  }

  void _clearCache(NaverMapController controller, Map<String, NMarker> cache) {
    if (cache.isEmpty) return;
    for (final entry in cache.entries) {
      final id = cache == _clusterCache ? 'cluster_${entry.key}' : entry.key;
      _safeDelete(controller, id);
    }
    cache.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<FleetVehicle>>>(
      fleetSnapshotsProvider,
      (_, next) {
        final vehicles = next.value;
        if (vehicles == null) return;
        _reconcile(vehicles);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _benchRunning
              ? 'BENCH $_benchStatus'
              : '관제 ${_mode.label[0]}. ${_mode.title}',
        ),
      ),
      // 측정 컨트롤: 렌더 모드(A/B/C) + 줌 프리셋. 콘솔 [PERF] 로그로 비교
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<RenderMode>(
                  // 체크 아이콘·기본 밀도는 좁은 화면에서 overflow 유발
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    for (final m in RenderMode.values)
                      ButtonSegment(value: m, label: Text(m.label[0])),
                  ],
                  selected: {_mode},
                  onSelectionChanged:
                      _benchRunning ? null : (s) => _setMode(s.first),
                ),
              ),
              const SizedBox(width: 4),
              // 줌 14: 도시 전역 분산 중 일부만 화면 내 → 컬링 측정
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                onPressed:
                    _benchRunning ? null : () => _applyZoomPreset(14),
                child: const Text('Z14'),
              ),
              // 줌 12: 클러스터 임계(13) 미만 → 클러스터 측정
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                onPressed:
                    _benchRunning ? null : () => _applyZoomPreset(12),
                child: const Text('Z12'),
              ),
              // 측정 시작/정지: 누른 시점부터만 수집 (이전 상태 미누적)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  FrameLogger.isActive
                      ? Icons.stop_circle
                      : Icons.play_circle_fill,
                  color: FrameLogger.isActive ? Colors.red : Colors.green,
                  size: 28,
                ),
                tooltip: FrameLogger.isActive ? '측정 정지' : '측정 시작',
                onPressed: _benchRunning ? null : _toggleMeasure,
              ),
              // 전체 시나리오 자동 실행 (규모×모드×줌 순회 후 [BENCH] 출력)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                onPressed: _benchRunning ? null : _runBenchmark,
                child: Text(_benchRunning ? '…' : 'AUTO'),
              ),
            ],
          ),
        ),
      ),
      body: NaverMap(
        options: const NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(37.5665, 126.9780),
            zoom: 14,
          ),
        ),
        onMapReady: (controller) {
          _mapController = controller;
          _refreshCamera();
          // 관제 진입만으로 전체 시나리오가 자동 측정되도록
          if (_autoStartBenchmark) {
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (mounted && !_benchRunning) _runBenchmark();
            });
          }
        },
        onCameraIdle: _refreshCamera,
      ),
    );
  }
}
