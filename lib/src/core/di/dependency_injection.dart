import 'package:get_it/get_it.dart';
import 'package:shalomly_app/src/core/di/bloc_initialization.dart';
import 'package:shalomly_app/src/core/di/core_init.dart';
import 'package:shalomly_app/src/core/di/network_initialization.dart';
import 'package:shalomly_app/src/core/di/repository_initialization.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';
import 'package:shalomly_app/src/features/giving/presentation/bloc/giving_bloc.dart';
import 'package:shalomly_app/src/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:shalomly_app/src/features/prayer/presentation/bloc/prayer_bloc.dart';

final getIt = GetIt.instance;

/// Configures all application dependencies (Core, Network, Repositories, BLoCs) in GetIt.
void configureDependencies() {
  initCore();
  initNetwork();
  initRepositories();
  initBlocs();
}

/// Closes the blocs holding the signed-in member's own data, so the next
/// lookup builds empty ones. Called by `MemberSessionScope` whenever a
/// different member, or nobody, is signed in.
void resetSessionDependencies() {
  if (getIt.isRegistered<EventsBloc>()) {
    getIt.resetLazySingleton<EventsBloc>();
  }
  if (getIt.isRegistered<PrayerBloc>()) {
    getIt.resetLazySingleton<PrayerBloc>();
  }
  if (getIt.isRegistered<GivingBloc>()) {
    getIt.resetLazySingleton<GivingBloc>();
  }
  if (getIt.isRegistered<GroupsBloc>()) {
    getIt.resetLazySingleton<GroupsBloc>();
  }
}
