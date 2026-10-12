import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/core/network/api_client.dart';
import 'package:shalomly_app/src/core/network/auth_interceptor.dart';

void initNetwork() {
  getIt
    ..registerLazySingleton<AuthInterceptor>(
      () => AuthInterceptor(tokenStorage: getIt(), appConfig: getIt()),
    )
    ..registerLazySingleton<Dio>(
      () => createDio(
        appConfig: getIt(),
        interceptors: [getIt<AuthInterceptor>()],
      ),
      dispose: (dio) => dio.close(),
    );
}
