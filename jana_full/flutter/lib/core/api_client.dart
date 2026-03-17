import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

Dio createApiClient() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // always read the current session - handles token refresh automatically
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      return handler.next(options);
    },
    onError: (DioException err, handler) {
      print('[API] ${err.requestOptions.method} ${err.requestOptions.path} '
            '→ ${err.response?.statusCode}: ${err.response?.data}');
      return handler.next(err);
    },
  ));

  return dio;
}
