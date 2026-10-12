import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/core/di/dependency_injection.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/widgets/member_session_scope.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';
import 'package:shalomly_app/src/features/giving/presentation/bloc/giving_bloc.dart';
import 'package:shalomly_app/src/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:shalomly_app/src/features/prayer/presentation/bloc/prayer_bloc.dart';

void main() {
  late _AuthStub auth;
  late BuildContext scoped;

  setUp(() {
    auth = _AuthStub();
    getIt
      ..registerLazySingleton<PrayerBloc>(
        _FakePrayerBloc.new,
        dispose: (b) => b.close(),
      )
      ..registerLazySingleton<GivingBloc>(
        _FakeGivingBloc.new,
        dispose: (b) => b.close(),
      )
      ..registerLazySingleton<GroupsBloc>(
        _FakeGroupsBloc.new,
        dispose: (b) => b.close(),
      )
      ..registerLazySingleton<EventsBloc>(
        _FakeEventsBloc.new,
        dispose: (b) => b.close(),
      );
  });

  tearDown(() async {
    await auth.close();
    await getIt.reset();
  });

  Future<void> pumpScope(WidgetTester tester) => tester.pumpWidget(
    BlocProvider<AuthBloc>.value(
      value: auth,
      child: MemberSessionScope(
        child: Builder(
          builder: (context) {
            scoped = context;
            MemberSessionScope.generationOf(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );

  _FakePrayerBloc prayerBloc() => scoped.read<PrayerBloc>() as _FakePrayerBloc;

  testWidgets('settling the launch sign-in check keeps the loaded data', (
    tester,
  ) async {
    await pumpScope(tester);
    final atLaunch = prayerBloc();

    auth.set(_signedIn(1));
    await tester.pump();

    expect(prayerBloc(), same(atLaunch));
    expect(atLaunch.loads, 1);
    expect(MemberSessionScope.generationOf(scoped), 0);
  });

  testWidgets('signing out replaces every member bloc with a fresh one', (
    tester,
  ) async {
    await pumpScope(tester);
    auth.set(_signedIn(1));
    await tester.pump();
    final ruths = [
      scoped.read<PrayerBloc>(),
      scoped.read<GivingBloc>(),
      scoped.read<GroupsBloc>(),
      scoped.read<EventsBloc>(),
    ];

    auth
      ..set(const AuthLoading())
      ..set(const UnauthenticatedGuest());
    await tester.pump();
    // Closing a bloc finishes asynchronously.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    final guests = [
      scoped.read<PrayerBloc>(),
      scoped.read<GivingBloc>(),
      scoped.read<GroupsBloc>(),
      scoped.read<EventsBloc>(),
    ];
    for (var i = 0; i < ruths.length; i++) {
      expect(guests[i], isNot(same(ruths[i])));
      expect(ruths[i].isClosed, isTrue);
    }
    expect(prayerBloc().loads, 1);
    expect(MemberSessionScope.generationOf(scoped), 1);
  });

  testWidgets('another member signing in gets fresh blocs too', (
    tester,
  ) async {
    await pumpScope(tester);
    auth.set(_signedIn(1));
    await tester.pump();
    final first = prayerBloc();

    auth.set(_signedIn(2));
    await tester.pump();

    expect(prayerBloc(), isNot(same(first)));
  });

  testWidgets('a failed sign-in by a guest keeps the guest data', (
    tester,
  ) async {
    await pumpScope(tester);
    auth.set(const UnauthenticatedGuest());
    await tester.pump();
    final guest = prayerBloc();

    auth
      ..set(const AuthLoading())
      ..set(const AuthFailure('Invalid identifier or password'))
      ..set(const UnauthenticatedGuest());
    await tester.pump();

    expect(prayerBloc(), same(guest));
  });
}

Authenticated _signedIn(int id) => Authenticated(
  User(
    id: id,
    tenantId: 1,
    fullName: 'Member $id',
    email: 'member$id@church.org',
    role: UserRole.member,
    languagePreference: 'en',
    privacySettings: const PrivacySettings(
      showEmail: false,
      showPhone: false,
      showInDirectory: true,
      giveAnonymously: false,
    ),
    isActive: true,
    createdAt: DateTime(2026),
  ),
);

class _AuthStub extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthStub() : super(const AuthInitial());

  void set(AuthState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePrayerBloc extends Bloc<PrayerEvent, PrayerState>
    implements PrayerBloc {
  int loads = 0;

  _FakePrayerBloc() : super(const PrayerInitial()) {
    on<PrayerChainFetchRequested>((_, _) => loads++);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGivingBloc extends Bloc<GivingEvent, GivingState>
    implements GivingBloc {
  _FakeGivingBloc() : super(const GivingInitial()) {
    on<GivingEvent>((_, _) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGroupsBloc extends Bloc<GroupsEvent, GroupsState>
    implements GroupsBloc {
  _FakeGroupsBloc() : super(const GroupsInitial()) {
    on<GroupsEvent>((_, _) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEventsBloc extends Bloc<EventsEvent, EventsState>
    implements EventsBloc {
  _FakeEventsBloc() : super(const EventsInitial()) {
    on<EventsEvent>((_, _) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
