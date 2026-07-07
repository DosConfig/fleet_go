import 'package:fleet_go/features/route/domain/entity/route_info.dart';

abstract class RouteRepository {
  Future<RouteInfo> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });
}
