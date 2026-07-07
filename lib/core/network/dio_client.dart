import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Dio createTmapDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://apis.openapi.sk.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['appKey'] = dotenv.env['TMAP_APP_KEY'] ?? '';
        handler.next(options);
      },
    ),
  );
  return dio;
}
