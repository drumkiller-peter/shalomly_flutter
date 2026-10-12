import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';

const _timeout = Duration(seconds: 15);

/// Builds the app's configured Dio instance.
Dio createDio({
  required AppConfig appConfig,
  List<Interceptor> interceptors = const [],
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.apiBaseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll(interceptors);

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false, // don't print bearer tokens
        responseHeader: false,
        requestBody: true,
        responseBody: true,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  return dio;
}
