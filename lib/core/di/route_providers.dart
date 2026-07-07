import 'package:fleet_go/core/network/dio_client.dart';
import 'package:fleet_go/features/route/data/repository/route_repository_impl.dart';
import 'package:fleet_go/features/route/domain/repository/route_repository.dart';
import 'package:fleet_go/features/route/domain/usecase/get_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_providers.g.dart';

@riverpod
RouteRepository routeRepository(Ref ref) {
  return RouteRepositoryImpl(createTmapDio());
}

@riverpod
GetRoute getRoute(Ref ref) {
  return GetRoute(ref.watch(routeRepositoryProvider));
}
