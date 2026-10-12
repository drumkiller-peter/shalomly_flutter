import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/core/routing/app_router.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/announcements/data/announcements_repository.dart';
import 'package:shalomly_app/src/features/announcements/presentation/bloc/announcements_bloc.dart';
import 'package:shalomly_app/src/features/auth/data/auth_repository.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/widgets/member_session_scope.dart';
import 'package:shalomly_app/src/features/bulletins/data/bulletins_repository.dart';
import 'package:shalomly_app/src/features/bulletins/presentation/bloc/bulletins_bloc.dart';
import 'package:shalomly_app/src/features/devotional/data/devotional_repository.dart';
import 'package:shalomly_app/src/features/devotional/presentation/bloc/devotional_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/giving/data/giving_repository.dart';
import 'package:shalomly_app/src/features/groups/data/groups_repository.dart';
import 'package:shalomly_app/src/features/hymns/data/hymns_repository.dart';
import 'package:shalomly_app/src/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:shalomly_app/src/features/prayer/data/prayer_repository.dart';
import 'package:shalomly_app/src/features/sermons/data/sermons_repository.dart';
import 'package:shalomly_app/src/features/sermons/presentation/bloc/sermons_bloc.dart';
import 'package:shalomly_app/src/features/service_times/data/service_times_repository.dart';
import 'package:shalomly_app/src/features/service_times/presentation/bloc/service_times_bloc.dart';

class ShalomlyApp extends StatefulWidget {
  /// The church's colors, chosen once at launch; see `ThemeRepository`.
  final ChurchTheme churchTheme;
  final AppConfig? appConfig;
  final AppDatabase? database;
  final TokenStorage? tokenStorage;

  const ShalomlyApp({
    super.key,
    required this.churchTheme,
    this.appConfig,
    this.database,
    this.tokenStorage,
  });

  @override
  State<ShalomlyApp> createState() => _ShalomlyAppState();
}

class _ShalomlyAppState extends State<ShalomlyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter();

    // Startup fetches run once here (the member's own data loads in
    // MemberSessionScope), not in build(): hot reload and locale
    // changes rebuild this widget and would dispatch them again.
    getIt<AuthBloc>().add(const AuthCheckRequested());
    getIt<DevotionalBloc>().add(DevotionalFetchRequested());
    getIt<HymnsBloc>().add(const HymnsFetchRequested());
    getIt<BulletinsBloc>().add(const LoadBulletins());
    getIt<SermonsBloc>().add(const LoadSermons());
    getIt<ServiceTimesBloc>().add(const LoadServiceTimes());
    getIt<AnnouncementsBloc>().add(const LoadAnnouncements());
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = widget.appConfig ?? getIt<AppConfig>();
    final database = widget.database ?? getIt<AppDatabase>();
    final tokenStorage = widget.tokenStorage ?? getIt<TokenStorage>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: appConfig),
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<TokenStorage>.value(value: tokenStorage),
        RepositoryProvider<AuthRepository>.value(value: getIt<AuthRepository>()),
        RepositoryProvider<DevotionalRepository>.value(
          value: getIt<DevotionalRepository>(),
        ),
        RepositoryProvider<HymnsRepository>.value(value: getIt<HymnsRepository>()),
        RepositoryProvider<EventsRepository>.value(value: getIt<EventsRepository>()),
        RepositoryProvider<PrayerRepository>.value(value: getIt<PrayerRepository>()),
        RepositoryProvider<GivingRepository>.value(value: getIt<GivingRepository>()),
        RepositoryProvider<BulletinsRepository>.value(
          value: getIt<BulletinsRepository>(),
        ),
        RepositoryProvider<SermonsRepository>.value(value: getIt<SermonsRepository>()),
        RepositoryProvider<GroupsRepository>.value(value: getIt<GroupsRepository>()),
        RepositoryProvider<AnnouncementsRepository>.value(
          value: getIt<AnnouncementsRepository>(),
        ),
        RepositoryProvider<ServiceTimesRepository>.value(
          value: getIt<ServiceTimesRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
          BlocProvider<DevotionalBloc>.value(value: getIt<DevotionalBloc>()),
          BlocProvider<HymnsBloc>.value(value: getIt<HymnsBloc>()),
          BlocProvider<BulletinsBloc>.value(value: getIt<BulletinsBloc>()),
          BlocProvider<SermonsBloc>.value(value: getIt<SermonsBloc>()),
          BlocProvider<ServiceTimesBloc>.value(value: getIt<ServiceTimesBloc>()),
          BlocProvider<AnnouncementsBloc>.value(value: getIt<AnnouncementsBloc>()),
        ],
        child: MemberSessionScope(
          child: MaterialApp.router(
            title: appConfig.churchName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(widget.churchTheme),
            darkTheme: AppTheme.dark(widget.churchTheme),
            themeMode: ThemeMode.system,
            routerConfig: _router,
            localizationsDelegates: [
              ...context.localizationDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US'), Locale('ne', 'NP')],
          ),
        ),
      ),
    );
  }
}
