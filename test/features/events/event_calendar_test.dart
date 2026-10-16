import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_days.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/calendar_events_bloc.dart';

ChurchEvent _event(
  int id,
  DateTime start, {
  DateTime? end,
  bool cancelled = false,
}) => ChurchEvent(
  id: id,
  title: 'Event $id',
  type: EventType.fellowship,
  startsAt: start,
  endsAt: end,
  isCancelled: cancelled,
);

class _FakeRepository extends EventsRepository {
  _FakeRepository() : super(dio: Dio());

  final asked = <({DateTime? after, DateTime? before, int pageSize})>[];
  List<ChurchEvent> calendar = [];
  bool failing = false;

  /// Answers held back until the test completes them, in the order asked.
  final gates = <Completer<List<ChurchEvent>>>[];

  @override
  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async {
    asked.add((after: startsAfter, before: startsBefore, pageSize: pageSize));
    if (failing) throw DioException(requestOptions: RequestOptions());
    if (gates.isNotEmpty) return gates.removeAt(0).future;
    return calendar;
  }
}

void main() {
  group('which Events are on a day', () {
    final friday = DateTime(2026, 10, 23);

    test('those that start on it, in time order', () {
      final evening = _event(1, DateTime(2026, 10, 23, 18));
      final morning = _event(2, DateTime(2026, 10, 23, 8));
      final otherDay = _event(3, DateTime(2026, 10, 24, 8));

      expect(eventsOnDay([evening, otherDay, morning], friday).map((e) => e.id), [2, 1]);
    });

    test('a conference that runs over several days is on every one of them', () {
      final conference = _event(
        1,
        DateTime(2026, 10, 23, 18),
        end: DateTime(2026, 10, 25, 12),
      );

      for (final day in [23, 24, 25]) {
        expect(eventsOnDay([conference], DateTime(2026, 10, day)), hasLength(1), reason: '$day');
      }
      expect(eventsOnDay([conference], DateTime(2026, 10, 26)), isEmpty);
      expect(eventsOnDay([conference], DateTime(2026, 10, 22)), isEmpty);
    });

    test('an Event that ends at midnight does not spill onto the next day', () {
      final lateNight = _event(1, DateTime(2026, 10, 23, 20), end: DateTime(2026, 10, 24));

      expect(eventsOnDay([lateNight], DateTime(2026, 10, 24)), isEmpty);
    });

    test('a cancelled Event is not on the calendar', () {
      expect(eventsOnDay([_event(1, DateTime(2026, 10, 23, 9), cancelled: true)], friday), isEmpty);
    });

    test('the time of day asked about does not matter', () {
      final event = _event(1, DateTime(2026, 10, 23, 9));

      expect(eventsOnDay([event], DateTime(2026, 10, 23, 23, 59)), hasLength(1));
    });
  });

  group('which dates to load for a month', () {
    test('the month and a week either side, so the weeks shown at its edges have their dots', () {
      final range = monthGridRange(DateTime(2026, 10, 15));

      expect(range.startsAfter, DateTime(2026, 9, 24));
      expect(range.startsBefore, DateTime(2026, 11, 8));
    });

    test('across a year end', () {
      final range = monthGridRange(DateTime(2026, 12, 3));

      expect(range.startsAfter, DateTime(2026, 11, 24));
      expect(range.startsBefore, DateTime(2027, 1, 8));
    });
  });

  group('the calendar\'s Events', () {
    late _FakeRepository repository;
    late CalendarEventsBloc bloc;

    setUp(() {
      repository = _FakeRepository();
      bloc = CalendarEventsBloc(repository: repository);
      addTearDown(bloc.close);
    });

    test('asks for the month around the day it was given, up to the backend\'s page limit', () async {
      bloc.add(CalendarEventsLoadRequested(DateTime(2026, 10, 15)));
      await pumpEventQueue();

      expect(repository.asked.single.after, DateTime(2026, 9, 24));
      expect(repository.asked.single.before, DateTime(2026, 11, 8));
      expect(repository.asked.single.pageSize, 100);
    });

    test('starts initial, then shows what it loaded', () async {
      expect(bloc.state.status, CalendarEventsStatus.initial);
      repository.calendar = [_event(1, DateTime(2026, 10, 23, 18))];

      bloc.add(CalendarEventsLoadRequested(DateTime(2026, 10, 15)));
      await pumpEventQueue();

      expect(bloc.state.status, CalendarEventsStatus.loaded);
      expect(bloc.state.events.map((e) => e.id), [1]);
    });

    test('keeps what it showed while the next month loads, and says so when it fails', () async {
      repository.calendar = [_event(1, DateTime(2026, 10, 23, 18))];
      bloc.add(CalendarEventsLoadRequested(DateTime(2026, 10, 15)));
      await pumpEventQueue();

      repository.failing = true;
      bloc.add(CalendarEventsLoadRequested(DateTime(2026, 11, 15)));
      await pumpEventQueue();

      expect(bloc.state.status, CalendarEventsStatus.error);
      expect(bloc.state.events.map((e) => e.id), [1]);
    });

    test('an older answer arriving late does not replace a newer one', () async {
      final october = Completer<List<ChurchEvent>>();
      final november = Completer<List<ChurchEvent>>();
      repository.gates.addAll([october, november]);
      bloc.add(CalendarEventsLoadRequested(DateTime(2026, 10, 15)));
      bloc.add(CalendarEventsLoadRequested(DateTime(2026, 11, 15)));
      await pumpEventQueue();

      november.complete([_event(2, DateTime(2026, 11, 20, 18))]);
      await pumpEventQueue();
      october.complete([_event(1, DateTime(2026, 10, 23, 18))]);
      await pumpEventQueue();

      expect(bloc.state.events.map((e) => e.id), [2]);
    });
  });
}
