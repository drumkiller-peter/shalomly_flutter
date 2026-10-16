import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';

class _FakeEventsRepository extends EventsRepository {
  _FakeEventsRepository() : super(dio: Dio());

  final created = <EventDraft>[];
  final fetches = <(DateTime?, DateTime?)>[];
  Set<int> failingCreates = {};
  List<ChurchEvent> calendar = [];

  @override
  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async {
    fetches.add((startsAfter, startsBefore));
    return calendar;
  }

  @override
  Future<ChurchEvent> createEvent(EventDraft draft) async {
    final attempt = created.length;
    created.add(draft);
    if (failingCreates.contains(attempt)) {
      throw DioException(requestOptions: RequestOptions());
    }
    return ChurchEvent(
      id: attempt + 1,
      title: draft.title,
      startsAt: draft.startsAt!,
    );
  }
}

EventDraft _weeklyWorship() => EventDraft(
  title: 'Sunday Worship',
  type: EventType.worship,
  startsAt: DateTime(2026, 10, 25, 10),
  repeatWeeklyForMonth: true,
);

Future<EventsLoaded> _posted(EventsBloc bloc) async =>
    (await bloc.stream.firstWhere(
      (s) => s is EventsLoaded && s.postedCount != null,
    )) as EventsLoaded;

void main() {
  late _FakeEventsRepository repository;
  late EventsBloc bloc;

  setUp(() {
    repository = _FakeEventsRepository();
    bloc = EventsBloc(repository: repository);
    addTearDown(bloc.close);
  });

  test('repeating for a month posts four Events and reloads the filter that was showing', () async {
    final pastFilter = (null, DateTime(2026, 10, 18));
    bloc.add(
      EventsFetchRequested(
        startsAfter: pastFilter.$1,
        startsBefore: pastFilter.$2,
      ),
    );
    await bloc.stream.firstWhere((s) => s is EventsLoaded);

    bloc.add(EventCreateRequested(_weeklyWorship()));
    final result = await _posted(bloc);

    expect(repository.created.map((d) => d.startsAt), [
      DateTime(2026, 10, 25, 10),
      DateTime(2026, 11, 1, 10),
      DateTime(2026, 11, 8, 10),
      DateTime(2026, 11, 15, 10),
    ]);
    expect(result.postedCount, 4);
    expect(result.postFailedCount, 0);
    expect(repository.fetches.last, pastFilter);
  });

  test('when some fail, the poster is told how many went through', () async {
    repository.failingCreates = {2, 3};

    bloc.add(EventCreateRequested(_weeklyWorship()));
    final result = await _posted(bloc);

    expect(result.postedCount, 2);
    expect(result.postFailedCount, 2);
  });

  test('a single Event is posted once', () async {
    bloc.add(
      EventCreateRequested(
        _weeklyWorship().copyWith(repeatWeeklyForMonth: false),
      ),
    );
    final result = await _posted(bloc);

    expect(repository.created, hasLength(1));
    expect(result.postedCount, 1);
  });
}
