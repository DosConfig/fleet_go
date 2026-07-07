import 'package:dio/dio.dart';
import 'package:fleet_go/features/route/data/dto/route_dto.dart';
import 'package:fleet_go/features/route/domain/entity/route_info.dart';
import 'package:fleet_go/features/route/domain/repository/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<RouteInfo> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final response = await _dio.post(
      '/tmap/routes',
      queryParameters: {'version': 1},
      data: {
        'startX': startLng.toString(),
        'startY': startLat.toString(),
        'endX': endLng.toString(),
        'endY': endLat.toString(),
        'reqCoordType': 'WGS84GEO',
        'resCoordType': 'WGS84GEO',
      },
    );

    return RouteDto.fromJson(response.data as Map<String, dynamic>);
  }
}
