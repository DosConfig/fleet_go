import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_info.freezed.dart';

@freezed
abstract class RouteInfo with _$RouteInfo {
  const factory RouteInfo({
    required List<({double lat, double lng})> coordinates,
    required int totalDistanceM,
    required int totalTimeSec,
  }) = _RouteInfo;
}
