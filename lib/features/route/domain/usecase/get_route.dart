import 'package:fleet_go/features/route/domain/entity/route_info.dart';
import 'package:fleet_go/features/route/domain/repository/route_repository.dart';

class GetRoute {
  GetRoute(this._repo);

  final RouteRepository _repo;

  Future<RouteInfo> call({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return _repo.getRoute(startLat: startLat, startLng: startLng, endLat: endLat, endLng: endLng);
  }
}
