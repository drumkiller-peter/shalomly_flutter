import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/devotional/domain/home_worship.dart';
import 'package:shalomly_app/src/features/devotional/presentation/bloc/home_events_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

ChurchEvent _worship(int id, DateTime start, {DateTime? end, String? description, String? pdf, bool cancelled = false}) =>
    ChurchEvent(
      id: id,
      title: 'Worship $id',
      type: EventType.worship,
      startsAt: start,
      endsAt: end,
      description: description,
      pdfUrl: pdf,
      isCancelled: cancelled,
    );

class _FakeRepository extends EventsRepository {
  _FakeRepository() : super(dio: Dio());

  final asked = <({List<EventType>? types, DateTime? after, DateTime? before, int? pageSize})>[];
  List<ChurchEvent> worship = [];
  List<ChurchEvent> notices = [];
  bool failing = false;

  @override
  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async {
    asked.add((types: types, after: startsAfter, before: startsBefore, pageSize: pageSize));
    if (failing) throw DioException(requestOptions: RequestOptions());
    return types!.contains(EventType.worship) ? worship : notices;
  }
}

void main() {
  final now = DateTime(2026, 10, 25, 10, 30);

  group('which Event is the next worship', () {
    test('a service in progress still counts, so its order of service is there during it', () {
      final earlier = _worship(1, DateTime(2026, 10, 25, 8), end: DateTime(2026, 10, 25, 9));
      final inProgress = _worship(2, DateTime(2026, 10, 25, 10), end: DateTime(2026, 10, 25, 12));
      final nextWeek = _worship(3, DateTime(2026, 11, 1, 10));

      expect(pickNextWorship([earlier, inProgress, nextWeek], now)?.id, 2);
    });

    test('with no end time a service is taken to last two hours', () {
      final started90MinutesAgo = _worship(1, DateTime(2026, 10, 25, 9));
      final nextWeek = _worship(2, DateTime(2026, 11, 1, 10));

      expect(pickNextWorship([started90MinutesAgo, nextWeek], now)?.id, 1);
      expect(pickNextWorship([started90MinutesAgo, nextWeek], DateTime(2026, 10, 25, 11, 1))?.id, 2);
    });

    test('a cancelled service is skipped, and no upcoming service is no card details', () {
      final cancelled = _worship(1, DateTime(2026, 10, 25, 11), cancelled: true);

      expect(pickNextWorship([cancelled], now), isNull);
      expect(pickNextWorship(const [], now), isNull);
    });

    test('Order of Service shows only when the Event has text or a PDF to read', () {
      expect(_worship(1, now).hasOrderOfService, isFalse);
      expect(_worship(1, now, description: '  ').hasOrderOfService, isFalse);
      expect(_worship(1, now, description: 'Hymns 12, 45').hasOrderOfService, isTrue);
      expect(_worship(1, now, pdf: 'https://example.org/o.pdf').hasOrderOfService, isTrue);
    });
  });

  group('what Home asks the backend for', () {
    late _FakeRepository repository;
    late HomeEventsBloc bloc;

    setUp(() {
      repository = _FakeRepository();
      bloc = HomeEventsBloc(repository: repository);
      addTearDown(bloc.close);
    });

    test('worship from the start of today, and Notices for the next seven days, three at most', () async {
      bloc.add(HomeEventsLoadRequested(now));
      await pumpEventQueue();

      final worship = repository.asked.firstWhere((a) => a.types!.contains(EventType.worship));
      expect(worship.types, [EventType.worship]);
      expect(worship.after, DateTime(2026, 10, 25));
      final notices = repository.asked.firstWhere((a) => a.types!.contains(EventType.notice));
      expect(notices.types, [EventType.notice]);
      expect(notices.after, DateTime(2026, 10, 25));
      expect(notices.before, DateTime(2026, 11, 1));
      expect(notices.pageSize, 3);
    });

    test('shows the next worship and the Notices it was given', () async {
      repository.worship = [_worship(2, DateTime(2026, 10, 25, 10), end: DateTime(2026, 10, 25, 12))];
      repository.notices = [
        ChurchEvent(id: 9, title: 'Office closed', type: EventType.notice, startsAt: DateTime(2026, 10, 26)),
      ];

      bloc.add(HomeEventsLoadRequested(now));
      await pumpEventQueue();

      expect(bloc.state.status, HomeEventsStatus.loaded);
      expect(bloc.state.nextWorship?.id, 2);
      expect(bloc.state.notices.map((e) => e.title), ['Office closed']);
    });

    test('when the backend can\'t be reached Home shows its plain card, without an error', () async {
      repository.failing = true;

      bloc.add(HomeEventsLoadRequested(now));
      await pumpEventQueue();

      expect(bloc.state.status, HomeEventsStatus.loaded);
      expect(bloc.state.nextWorship, isNull);
      expect(bloc.state.notices, isEmpty);
    });
  });
}
