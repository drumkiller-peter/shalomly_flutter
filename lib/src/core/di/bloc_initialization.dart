import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/features/announcements/presentation/bloc/announcements_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/bulletins/presentation/bloc/bulletins_bloc.dart';
import 'package:shalomly_app/src/features/devotional/presentation/bloc/devotional_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';
import 'package:shalomly_app/src/features/giving/presentation/bloc/giving_bloc.dart';
import 'package:shalomly_app/src/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:shalomly_app/src/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:shalomly_app/src/features/prayer/presentation/bloc/prayer_bloc.dart';
import 'package:shalomly_app/src/features/sermons/presentation/bloc/sermons_bloc.dart';
import 'package:shalomly_app/src/features/service_times/presentation/bloc/service_times_bloc.dart';

void initBlocs() {
  getIt
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(authRepository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<DevotionalBloc>(
      () => DevotionalBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<HymnsBloc>(
      () => HymnsBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<EventsBloc>(
      () => EventsBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<PrayerBloc>(
      () => PrayerBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<GivingBloc>(
      () => GivingBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<BulletinsBloc>(
      () => BulletinsBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<SermonsBloc>(
      () => SermonsBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<GroupsBloc>(
      () => GroupsBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<AnnouncementsBloc>(
      () => AnnouncementsBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerLazySingleton<ServiceTimesBloc>(
      () => ServiceTimesBloc(repository: getIt()),
      dispose: (bloc) => bloc.close(),
    );
}
