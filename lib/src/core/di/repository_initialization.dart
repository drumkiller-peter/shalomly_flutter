import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/core/network/auth_interceptor.dart';
import 'package:shalomly_app/src/core/theme/theme_repository.dart';
import 'package:shalomly_app/src/features/announcements/data/announcements_repository.dart';
import 'package:shalomly_app/src/features/auth/data/auth_repository.dart';
import 'package:shalomly_app/src/features/bulletins/data/bulletins_repository.dart';
import 'package:shalomly_app/src/features/devotional/data/devotional_repository.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/giving/data/giving_repository.dart';
import 'package:shalomly_app/src/features/groups/data/groups_repository.dart';
import 'package:shalomly_app/src/features/hymns/data/hymns_repository.dart';
import 'package:shalomly_app/src/features/prayer/data/prayer_repository.dart';
import 'package:shalomly_app/src/features/sermons/data/sermons_repository.dart';
import 'package:shalomly_app/src/features/service_times/data/service_times_repository.dart';

void initRepositories() {
  getIt
    ..registerLazySingleton<ThemeRepository>(
      () => ThemeRepository(
        dio: getIt(),
        db: getIt(),
        appConfig: getIt(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        dio: getIt(),
        tokenStorage: getIt(),
        sessionExpired: getIt<AuthInterceptor>().sessionExpired,
      ),
    )
    ..registerLazySingleton<DevotionalRepository>(
      () => DevotionalRepository(
        dio: getIt(),
        db: getIt(),
      ),
    )
    ..registerLazySingleton<HymnsRepository>(
      () => HymnsRepository(
        dio: getIt(),
        db: getIt(),
        appConfig: getIt(),
      ),
    )
    ..registerLazySingleton<EventsRepository>(
      () => EventsRepository(dio: getIt()),
    )
    ..registerLazySingleton<PrayerRepository>(
      () => PrayerRepository(dio: getIt()),
    )
    ..registerLazySingleton<GivingRepository>(
      () => GivingRepository(dio: getIt()),
    )
    ..registerLazySingleton<BulletinsRepository>(
      () => BulletinsRepository(
        dio: getIt(),
        database: getIt(),
        config: getIt(),
      ),
    )
    ..registerLazySingleton<SermonsRepository>(
      () => SermonsRepository(dio: getIt()),
    )
    ..registerLazySingleton<GroupsRepository>(
      () => GroupsRepository(dio: getIt()),
    )
    ..registerLazySingleton<AnnouncementsRepository>(
      () => AnnouncementsRepository(dio: getIt()),
    )
    ..registerLazySingleton<ServiceTimesRepository>(
      () => ServiceTimesRepository(
        dio: getIt(),
        db: getIt(),
        appConfig: getIt(),
      ),
    );
}
