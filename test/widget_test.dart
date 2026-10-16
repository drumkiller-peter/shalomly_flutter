import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/localization/bilingual_text.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:shalomly_app/src/features/auth/presentation/screens/register_screen.dart';
import 'package:shalomly_app/src/features/devotional/domain/daily_quote.dart';
import 'package:shalomly_app/src/features/devotional/presentation/bloc/devotional_bloc.dart';
import 'package:shalomly_app/src/features/devotional/presentation/screens/home_screen.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';
import 'package:shalomly_app/src/features/giving/domain/fund.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';
import 'package:shalomly_app/src/features/hymns/domain/hymn.dart';
import 'package:shalomly_app/src/features/prayer/domain/prayer_request.dart';
import 'package:shalomly_app/src/features/prayer/presentation/bloc/prayer_bloc.dart';
import 'package:shalomly_app/src/features/prayer/presentation/screens/prayer_screen.dart';
import 'package:shalomly_app/src/features/sermons/domain/sermon.dart';
import 'package:shalomly_app/src/features/sermons/presentation/bloc/sermons_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    EasyLocalization.logger.enableLevels = [];
  });

  group('Core Domain Smoke Tests', () {
    test('AppConfig resolves default tenant key', () {
      final config = AppConfig.resolve();
      expect(config.tenantKey, equals('sbc'));
      expect(config.churchName, isNotEmpty);
    });

    test('BilingualText resolves according to locale fallback', () {
      const text = BilingualText(
        en: 'Praise the Lord',
        ne: 'प्रभुको स्तुति होस्',
      );
      expect(text.resolve(const Locale('en')), equals('Praise the Lord'));
      expect(text.resolve(const Locale('ne')), equals('प्रभुको स्तुति होस्'));
    });

    test('User roles map correctly to leadership permissions', () {
      expect(UserRole.values.length, equals(7));
      expect(UserRole.pastor.isLeadership, isTrue);
      expect(UserRole.admin.isLeadership, isTrue);
      expect(UserRole.admin.canManageContent, isTrue);
      expect(UserRole.admin.isFinanceManager, isFalse);
      expect(UserRole.admin.canAccessPrivatePrayers, isFalse);

      expect(UserRole.treasurer.isFinanceManager, isTrue);
      expect(UserRole.treasurer.canManageContent, isFalse);

      expect(UserRole.youthLeader.canPostChurchEvents, isTrue);
      expect(UserRole.youthLeader.canCreateGroups, isTrue);
      expect(UserRole.youthLeader.isLeadership, isFalse);
      expect(UserRole.youthLeader.canManageContent, isFalse);

      expect(UserRole.elder.canPostChurchEvents, isFalse);
      expect(UserRole.elder.canCreateGroups, isFalse);
      expect(UserRole.elder.isLeadership, isFalse);

      expect(UserRole.member.canPostChurchEvents, isFalse);
      expect(UserRole.member.canCreateGroups, isFalse);
      expect(UserRole.member.isLeadership, isFalse);
    });

    test('Hymn model serialization and bookmarking', () {
      const hymn = Hymn(
        id: 1,
        hymnNumber: 1,
        titleEn: 'Amazing Grace',
        titleNe: 'कस्तो अनौठो अनुग्रह',
        lyricsEn: 'Amazing grace how sweet the sound...',
        lyricsNe: 'कस्तो अनौठो अनुग्रह...',
      );

      final bookmarked = hymn.copyWith(isBookmarked: true);
      expect(bookmarked.isBookmarked, isTrue);
      expect(hymn.isBookmarked, isFalse);
    });

    test('Prayer request confidentiality per ADR 0001', () {
      final prayer = PrayerRequest(
        id: 1,
        title: 'Healing prayer',
        content: 'Please pray for recovery',
        isPrivate: true,
        assignedPastorId: 10,
        createdAt: DateTime.now(),
      );

      expect(prayer.isPrivate, isTrue);
      expect(prayer.assignedPastorId, equals(10));
    });

    test('PrayerRequest deserializes backend PrayerRequestDetail and unassigned pastor', () {
      final chainJson = {
        'id': 42,
        'tenant_id': 1,
        'scope': 'chain',
        'content': 'Pray for our youth conference this weekend.',
        'is_anonymous': false,
        'status': 'open',
        'pray_count': 15,
        'is_interceding': true,
        'created_at': '2026-10-05T00:00:00Z',
      };
      final chainPrayer = PrayerRequest.fromJson(chainJson);
      expect(chainPrayer.id, equals(42));
      expect(chainPrayer.isPrivate, isFalse);
      expect(chainPrayer.intercessionCount, equals(15));
      expect(chainPrayer.hasInterceded, isTrue);

      final privateJson = {
        'id': 43,
        'tenant_id': 1,
        'scope': 'private',
        'content': 'Personal pastoral guidance needed.',
        'is_anonymous': false,
        'status': 'open',
        'assigned_pastor_id': null,
        'created_at': '2026-10-05T00:00:00Z',
      };
      final privatePrayer = PrayerRequest.fromJson(privateJson);
      expect(privatePrayer.isPrivate, isTrue);
      expect(privatePrayer.assignedPastorId, isNull);
    });

    test('Church fund visibility per backend rules', () {
      const fund = ChurchFund(
        id: 1,
        name: 'Tithes & Offerings',
        code: 'TITHES',
        visibility: FundVisibility.totals,
        balance: 50000.0,
      );

      expect(fund.visibility, equals(FundVisibility.totals));
      expect(fund.balance, equals(50000.0));
    });

    test('Sermon model derives YouTube video URL and thumbnail', () {
      final sermon = Sermon.fromJson({
        'id': 5,
        'tenant_id': 1,
        'title': 'The Beatitudes',
        'preacher': 'Rev. Ramesh Tamang',
        'preached_on': '2026-09-27',
        'youtube_video_id': 'dQw4w9WgXcQ',
        'description': 'Exposition of Matthew 5',
      });

      expect(
        sermon.youtubeUrl,
        equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      );
      expect(
        sermon.thumbnailUrl,
        equals('https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
      );
      expect(sermon.preacher, equals('Rev. Ramesh Tamang'));
    });

    test('Group models align with ADR 0004', () {
      final group = Group.fromJson({
        'id': 3,
        'tenant_id': 1,
        'name': 'Young Adults Fellowship',
        'group_type': 'bible_study',
        'meeting_schedule': 'Saturday 4:00 PM',
        'member_count': 25,
        'is_member': false,
      });

      expect(group.groupType, equals(GroupType.bibleStudy));
      expect(group.memberCount, equals(25));
      expect(group.isMember, isFalse);

      final joined = group.copyWith(isMember: true, memberCount: 26);
      expect(joined.isMember, isTrue);
      expect(joined.memberCount, equals(26));
    });

    test('ChurchEvent 3-way RSVP aligns with ADR 0004', () {
      final event = ChurchEvent.fromJson({
        'id': 42,
        'tenant_id': 1,
        'title': 'Church Picnic & Fellowship',
        'start_at': '2026-10-15T10:00:00Z',
        'location_name': 'Central Park',
        'attending_count': 50,
        'maybe_count': 10,
        'declined_count': 2,
        'my_rsvp': 'attending',
      });

      expect(event.myRsvp, equals(RSVPStatus.attending));
      expect(event.attendingCount, equals(50));
      expect(event.maybeCount, equals(10));
      expect(event.location, equals('Central Park'));

      final updated = event.copyWith(
        myRsvp: RSVPStatus.declined,
        attendingCount: 49,
        declinedCount: 3,
      );
      expect(updated.myRsvp, equals(RSVPStatus.declined));
      expect(updated.attendingCount, equals(49));
      expect(updated.declinedCount, equals(3));
    });

    test('AppTheme modern sanctuary design tokens and geometry', () {
      final themeData = AppTheme.light(
        const ChurchTheme(
          light: ChurchColors.defaultLight,
          dark: ChurchColors.defaultDark,
        ),
      );

      expect(themeData.useMaterial3, isTrue);
      expect(themeData.cardTheme.shape, isA<RoundedRectangleBorder>());
      final cardShape = themeData.cardTheme.shape as RoundedRectangleBorder;
      expect((cardShape.borderRadius as BorderRadius).topLeft.x, equals(16.0));
      expect(themeData.navigationBarTheme.indicatorColor, isNotNull);
      expect(
        themeData.textTheme.titleLarge?.fontWeight,
        equals(FontWeight.w700),
      );
    });

    test(
      'DailyQuote fallback provides inspirational scripture on empty state',
      () {
        expect(DailyQuote.fallback.content, contains('Do not be anxious'));
        expect(DailyQuote.fallback.authorName, equals('Philippians 4:6-7'));
        expect(DailyQuote.fallback.id, equals(0));
      },
    );

    test(
      'Sermon fallback provides inspirational featured sermon on empty state',
      () {
        expect(Sermon.fallback.title, contains('The Sermon on the Mount'));
        expect(Sermon.fallback.preacher, equals('Rev. Ramesh Tamang'));
        expect(Sermon.fallback.youtubeVideoId, equals('dQw4w9WgXcQ'));
        expect(Sermon.fallback.thumbnailUrl, contains('hqdefault.jpg'));
      },
    );
  });

  group('Home Feed Modern Sanctuary UI Tests', () {
    const defaultTheme = ChurchTheme(
      light: ChurchColors.defaultLight,
      dark: ChurchColors.defaultDark,
    );

    Widget createHarness({
      required ChurchTheme churchTheme,
      required ThemeMode themeMode,
      AuthBloc? authBloc,
      DevotionalBloc? devotionalBloc,
      SermonsBloc? sermonsBloc,
      EventsRepository? eventsRepository,
    }) {
      final appConfig = AppConfig.resolve();
      return EasyLocalization(
        key: UniqueKey(),
        supportedLocales: const [Locale('en', 'US'), Locale('ne', 'NP')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        startLocale: const Locale('en', 'US'),
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AppConfig>.value(value: appConfig),
            RepositoryProvider<EventsRepository>.value(
              value: eventsRepository ?? TestEventsRepository(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc ?? TestAuthBloc()),
              BlocProvider<DevotionalBloc>.value(
                value: devotionalBloc ?? TestDevotionalBloc(),
              ),
              BlocProvider<SermonsBloc>.value(
                value: sermonsBloc ?? TestSermonsBloc(),
              ),
            ],
            child: Builder(
              builder: (context) {
                return MaterialApp(
                  theme: AppTheme.light(churchTheme),
                  darkTheme: AppTheme.dark(churchTheme),
                  themeMode: themeMode,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: [
                    ...context.localizationDelegates,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const HomeScreen(),
                );
              },
            ),
          ),
        ),
      );
    }

    /// Pumps [harness] and lets EasyLocalization load its translations,
    /// which reads assets with real I/O the fake test clock doesn't wait for.
    Future<void> pumpHarness(WidgetTester tester, Widget harness) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(harness);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }

    testWidgets('Home Feed renders completely in Light Theme', (tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHarness(
        tester,
        createHarness(churchTheme: defaultTheme, themeMode: ThemeMode.light),
      );
      await tester.pumpAndSettle();

      // 1. App Bar Header & Greeting
      expect(find.text('SBC Church'), findsOneWidget);
      expect(find.text('Welcome to Fellowship'), findsOneWidget);

      // 2. Worship spotlight, with no worship Event: no day or time is
      // invented, and the button leads to the calendar
      expect(find.text('WEEKLY WORSHIP'), findsOneWidget);
      expect(find.text('Worship With Us'), findsOneWidget);
      expect(find.text('View Events'), findsOneWidget);
      expect(find.text('Order of Service'), findsNothing);
      expect(find.text('Watch Live'), findsNothing);
      expect(find.text('Notices this week'), findsNothing);

      // 3. Shortcuts: no Bulletins or Announcements any more, and the Church
      // Workspace only for church leaders (this visitor is signed out)
      expect(find.text('Bulletins'), findsNothing);
      expect(find.text('Announcements'), findsNothing);
      expect(find.text('Watch Sermons'), findsOneWidget);
      expect(find.text('Small Groups'), findsOneWidget);
      expect(find.text('Church Workspace'), findsNothing);

      // 4. The day strip moved to the calendar on the Events tab
      expect(find.text('SUN'), findsNothing);
      expect(find.text('MON'), findsNothing);

      // 5. 3-Card Sanctuary Devotional Layout
      expect(find.text("TODAY'S SCRIPTURE"), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);
      expect(find.text('PRAYER FOR TODAY'), findsOneWidget);
      expect(find.text('Copy Verse'), findsOneWidget);
      expect(find.text('Pray'), findsOneWidget);
      expect(find.text('Hymnal'), findsOneWidget);

      // 6. Fellowship Highlights Pulse Cards
      expect(find.text('FELLOWSHIP HIGHLIGHTS'), findsOneWidget);
      expect(find.text('Community Intercession & Gatherings'), findsOneWidget);
      expect(find.text('Intercession'), findsOneWidget);
      expect(find.text('Gatherings'), findsOneWidget);
      expect(find.text('Pray Together'), findsOneWidget);
      expect(find.text('View Schedule'), findsOneWidget);

      // 7. Featured Sermon Media Spotlight
      expect(find.text('FEATURED SERMON'), findsOneWidget);
      expect(find.text('All Sermons'), findsOneWidget);
      expect(find.text('Watch Sermon'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Rev. Ramesh Tamang'), findsOneWidget);
    });

    testWidgets('Home Feed renders completely in Dark Theme', (tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpHarness(
        tester,
        createHarness(churchTheme: defaultTheme, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Fellowship'), findsOneWidget);
      expect(find.text('WEEKLY WORSHIP'), findsOneWidget);
      expect(find.text('Watch Sermons'), findsOneWidget);
      expect(find.text("TODAY'S SCRIPTURE"), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);
      expect(find.text('PRAYER FOR TODAY'), findsOneWidget);
      expect(find.text('FELLOWSHIP HIGHLIGHTS'), findsOneWidget);
      expect(find.text('FEATURED SERMON'), findsOneWidget);
    });

    testWidgets(
      'Home Feed greets authenticated member with personalized greeting and role badge',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final user = User(
          id: 42,
          email: 'pastor@church.org',
          fullName: 'Barnabas Paul',
          role: UserRole.pastor,
          tenantId: 1,
          languagePreference: '',
          privacySettings: const PrivacySettings(
            showEmail: true,
            showPhone: true,
            showInDirectory: true,
            giveAnonymously: false,
          ),
          isActive: true,
          createdAt: DateTime.now(),
        );

        final authBloc = TestAuthBloc(Authenticated(user));

        await pumpHarness(
          tester,
          createHarness(
            churchTheme: defaultTheme,
            themeMode: ThemeMode.light,
            authBloc: authBloc,
          ),
        );
        await tester.pumpAndSettle();

        // Check personalized greeting containing first name
        expect(find.textContaining('Barnabas'), findsOneWidget);
        // Check leadership role chip
        expect(find.text('PASTOR'), findsWidgets);
      },
    );

    testWidgets('LoginScreen renders sanctuary hero header and form inputs', (
      tester,
    ) async {
      final appConfig = AppConfig.resolve();
      await tester.pumpWidget(
        RepositoryProvider<AppConfig>.value(
          value: appConfig,
          child: BlocProvider<AuthBloc>.value(
            value: TestAuthBloc(),
            child: MaterialApp(
              theme: AppTheme.light(defaultTheme),
              home: const LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SBC Church'), findsOneWidget);
      expect(
        find.text('Your church community, always within reach'),
        findsOneWidget,
      );
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in to continue to your church'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets(
      'RegisterScreen renders sanctuary hero header and registration inputs',
      (tester) async {
        final appConfig = AppConfig.resolve();
        await tester.pumpWidget(
          RepositoryProvider<AppConfig>.value(
            value: appConfig,
            child: BlocProvider<AuthBloc>.value(
              value: TestAuthBloc(),
              child: MaterialApp(
                theme: AppTheme.light(defaultTheme),
                home: const RegisterScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SBC Church'), findsOneWidget);
        expect(find.text('Connect with our church family'), findsOneWidget);
        expect(find.text('Join Congregation'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
      },
    );

    testWidgets(
      'PrayerScreen renders sanctuary header and prayer chain testimonies',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 3000);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final samplePrayer = PrayerRequest(
          id: 1,
          title: 'Healing and Peace in Family',
          content: 'Praying for my mother who is recovering from surgery. God has been so faithful!',
          authorName: 'Grace Williams',
          createdAt: DateTime(2026, 10, 4),
          intercessionCount: 87,
          hasInterceded: false,
        );

        final prayerBloc = TestPrayerBloc(
          PrayerLoaded(publicPrayers: [samplePrayer], privatePrayers: const []),
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: TestAuthBloc()),
              BlocProvider<PrayerBloc>.value(value: prayerBloc),
            ],
            child: MaterialApp(
              theme: AppTheme.light(defaultTheme),
              home: const PrayerScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Testimonies & Prayer'), findsOneWidget);
        expect(find.text('Ask for Prayer'), findsOneWidget);
        expect(find.text('Grace Williams'), findsOneWidget);
        expect(find.text('G'), findsOneWidget);
        expect(find.text('Healing and Peace in Family'), findsOneWidget);
        expect(
          find.text(
            '“Praying for my mother who is recovering from surgery. God has been so faithful!”',
          ),
          findsOneWidget,
        );
        expect(find.text('Intercede (87)'), findsOneWidget);
      },
    );
  });
}

class TestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  TestAuthBloc([super.initialState = const UnauthenticatedGuest()]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestDevotionalBloc extends Bloc<DevotionalEvent, DevotionalState>
    implements DevotionalBloc {
  TestDevotionalBloc([super.initialState = const DevotionalState()]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestSermonsBloc extends Bloc<SermonsEvent, SermonsState>
    implements SermonsBloc {
  TestSermonsBloc([super.initialState = const SermonsInitial()]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An Events API that has no Events, so Home shows its plain worship card.
class TestEventsRepository extends EventsRepository {
  TestEventsRepository() : super(dio: Dio());

  @override
  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async => const [];
}

class TestPrayerBloc extends Bloc<PrayerEvent, PrayerState>
    implements PrayerBloc {
  TestPrayerBloc([super.initialState = const PrayerInitial()]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
