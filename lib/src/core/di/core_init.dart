import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';

void initCore() {
  getIt
    ..registerLazySingleton<AppConfig>(() => AppConfig.fromEnv())
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    )
    ..registerLazySingleton<TokenStorage>(() => TokenStorage(storage: getIt()))
    ..registerLazySingleton<AppDatabase>(
      () => AppDatabase(),
      dispose: (db) => db.close(),
    );
}
