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

    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      // 디버그: 실제 응답 내용 확인
      throw Exception('TMAP 응답 타입=${data.runtimeType}, status=${response.statusCode}, body=$data');
    }
    return RouteDto.fromJson(data);
  }
}
