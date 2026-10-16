import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/routing/main_shell.dart';
import 'package:shalomly_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:shalomly_app/src/features/auth/presentation/screens/register_screen.dart';
import 'package:shalomly_app/src/features/devotional/presentation/screens/home_screen.dart';
import 'package:shalomly_app/src/features/events/presentation/screens/event_detail_screen.dart';
import 'package:shalomly_app/src/features/events/presentation/screens/events_screen.dart';
import 'package:shalomly_app/src/features/giving/presentation/screens/giving_screen.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';
import 'package:shalomly_app/src/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:shalomly_app/src/features/groups/presentation/screens/groups_screen.dart';
import 'package:shalomly_app/src/features/hymns/presentation/screens/hymns_screen.dart';
import 'package:shalomly_app/src/features/prayer/presentation/screens/prayer_screen.dart';
import 'package:shalomly_app/src/features/sermons/presentation/screens/sermons_screen.dart';
import 'package:shalomly_app/src/features/watch/presentation/screens/watch_glance_screen.dart';
import 'package:shalomly_app/src/features/workspace/presentation/screens/church_workspace_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Declarative GoRouter configuration conforming to ADR 0008 and ADR 0005.
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.devotional,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.devotional,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hymns,
                builder: (context, state) => const HymnsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.prayer,
                builder: (context, state) => const PrayerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.giving,
                builder: (context, state) => const GivingScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.eventDetailPattern,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.sermons,
        builder: (context, state) => const SermonsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.groups,
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.groupDetailsPattern,
        builder: (context, state) {
          final extra = state.extra;
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          if (extra is Group) {
            return GroupDetailScreen(group: extra);
          }
          return GroupDetailScreen(
            group: Group(
              id: id,
              tenantId: 1,
              name: 'Group #$id',
              groupType: GroupType.other,
              isOpen: true,
              isArchived: false,
              memberCount: 0,
              isMember: false,
              isLeader: false,
              createdAt: DateTime.now(),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.admin,
        builder: (context, state) => const ChurchWorkspaceScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.workspace,
        builder: (context, state) => const ChurchWorkspaceScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.watchGlance,
        builder: (context, state) => const WatchGlanceScreen(),
      ),
    ],
  );
}
