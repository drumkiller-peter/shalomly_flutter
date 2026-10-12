import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';
import 'package:shalomly_app/src/features/giving/presentation/bloc/giving_bloc.dart';
import 'package:shalomly_app/src/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:shalomly_app/src/features/prayer/presentation/bloc/prayer_bloc.dart';

/// Provides the blocs that hold the signed-in member's own data (their
/// Private Prayer Requests, giving, Groups and RSVPs) and replaces them with
/// fresh ones whenever a different member, or nobody, is signed in. On a
/// shared phone, one member never sees the last one's data.
///
/// Must sit below the [AuthBloc] provider.
class MemberSessionScope extends StatefulWidget {
  final Widget child;

  const MemberSessionScope({super.key, required this.child});

  /// Changes each time the session blocs are replaced. A screen that loads
  /// its own data with its own filters reloads when this changes; see
  /// `EventsScreen`.
  static int generationOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SessionGeneration>()!
      .generation;

  @override
  State<MemberSessionScope> createState() => _MemberSessionScopeState();
}

class _MemberSessionScopeState extends State<MemberSessionScope> {
  /// Whom the current blocs hold data for; null for a guest.
  int? _memberId;

  /// False until the launch sign-in check settles. The launch loads already
  /// used the stored session, so settling it needs no reload.
  bool _settled = false;

  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _onAuthChanged(BuildContext context, AuthState state) {
    final int? memberId;
    if (state is Authenticated) {
      memberId = state.user.id;
    } else if (state is UnauthenticatedGuest) {
      memberId = null;
    } else {
      return; // Loading or a failed attempt: nobody new yet.
    }

    final changed = _settled && memberId != _memberId;
    _settled = true;
    _memberId = memberId;
    if (!changed) return;

    resetSessionDependencies();
    setState(() => _generation++);
    _load();
  }

  /// What the app loads at launch, now for whoever is signed in.
  void _load() {
    getIt<PrayerBloc>().add(const PrayerChainFetchRequested());
    getIt<GivingBloc>().add(const GivingOverviewFetchRequested());
    getIt<GroupsBloc>().add(const LoadGroups());
    getIt<EventsBloc>().add(const EventsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthChanged,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PrayerBloc>.value(value: getIt<PrayerBloc>()),
          BlocProvider<GivingBloc>.value(value: getIt<GivingBloc>()),
          BlocProvider<GroupsBloc>.value(value: getIt<GroupsBloc>()),
          BlocProvider<EventsBloc>.value(value: getIt<EventsBloc>()),
        ],
        child: _SessionGeneration(
          generation: _generation,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SessionGeneration extends InheritedWidget {
  final int generation;

  const _SessionGeneration({required this.generation, required super.child});

  @override
  bool updateShouldNotify(_SessionGeneration oldWidget) =>
      generation != oldWidget.generation;
}
