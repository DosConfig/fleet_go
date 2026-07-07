import 'package:fleet_go/features/route/domain/entity/route_info.dart';

class RouteDto {
  RouteDto._();

  static RouteInfo fromJson(Map<String, dynamic> json) {
    final features = json['features'] as List<dynamic>;

    final coords = <({double lat, double lng})>[];
    int totalDistance = 0;
    int totalTime = 0;

    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;
      final type = geometry['type'] as String;

      if (type == 'Point') {
        totalDistance += (properties['totalDistance'] as num?)?.toInt() ?? 0;
        totalTime += (properties['totalTime'] as num?)?.toInt() ?? 0;
      } else if (type == 'LineString') {
        final rawCoords = geometry['coordinates'] as List;
        for (final c in rawCoords) {
          final pair = c as List;
          coords.add((lat: (pair[1] as num).toDouble(), lng: (pair[0] as num).toDouble()));
        }
      }
    }

    return RouteInfo(coordinates: coords, totalDistanceM: totalDistance, totalTimeSec: totalTime);
  }
}
