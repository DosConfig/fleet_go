import 'package:fleet_go/core/di/route_providers.dart';
import 'package:fleet_go/features/route/domain/entity/route_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_state_provider.g.dart';

@riverpod
Future<RouteInfo> tripRoute(
  Ref ref, {
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
}) {
  return ref.watch(getRouteProvider).call(startLat: startLat, startLng: startLng, endLat: endLat, endLng: endLng);
}
