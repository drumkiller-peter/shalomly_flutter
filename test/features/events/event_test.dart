import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_days.dart';
import 'package:shalomly_app/src/features/events/domain/event_time_filter.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

Map<String, dynamic> _json({
  Object? type = 'worship',
  int id = 1,
  String start = '2026-10-18T10:00:00Z',
}) => {
  'id': id,
  'tenant_id': 1,
  'title': 'Sunday Worship',
  'type': ?type,
  'start_at': start,
  'pdf_url': 'https://example.org/order.pdf',
  'image_url': 'https://example.org/banner.jpg',
  'created_by_id': 7,
};

ChurchEvent _event(int id, DateTime start) => ChurchEvent(
  id: id,
  title: 'Event $id',
  startsAt: start,
  type: EventType.fellowship,
);

void main() {
  group('ChurchEvent from the API', () {
    test('reads its type, links and who posted it', () {
      final event = ChurchEvent.fromJson(_json());

      expect(event.type, EventType.worship);
      expect(event.pdfUrl, 'https://example.org/order.pdf');
      expect(event.imageUrl, 'https://example.org/banner.jpg');
      expect(event.createdById, 7);
    });

    test('times are read in the member\'s own time zone, not UTC', () {
      final event = ChurchEvent.fromJson(_json());

      expect(event.startsAt.isUtc, isFalse);
      expect(
        event.startsAt.isAtSameMomentAs(DateTime.utc(2026, 10, 18, 10)),
        isTrue,
      );
    });

    test('an unknown or missing type reads as other', () {
      expect(
        ChurchEvent.fromJson(_json(type: 'potluck')).type,
        EventType.other,
      );
      expect(ChurchEvent.fromJson(_json(type: null)).type, EventType.other);
    });

    test('every type the backend knows is understood', () {
      for (final value in [
        'worship',
        'fellowship',
        'conference',
        'bible_study',
        'prayer_meeting',
        'outreach',
        'celebration',
        'notice',
        'other',
      ]) {
        expect(EventType.fromValue(value).value, value);
      }
    });
  });

  group('the filters partition the calendar around the start of today', () {
    final now = DateTime(2026, 10, 18, 15, 30);
    final todayStart = DateTime(2026, 10, 18);

    test('All Upcoming starts at the beginning of today, so this morning is included', () {
      final range = EventTimeFilter.upcoming.rangeAt(now);

      expect(range.startsAfter, todayStart);
      expect(range.startsBefore, isNull);
    });

    test('This Week covers today and the next seven days', () {
      final range = EventTimeFilter.thisWeek.rangeAt(now);

      expect(range.startsAfter, todayStart);
      expect(range.startsBefore, DateTime(2026, 10, 25));
    });

    test('only Past Events ask for the most recent first, so page one is last Sunday', () {
      expect(EventTimeFilter.past.rangeAt(now).newestFirst, isTrue);
      expect(EventTimeFilter.upcoming.rangeAt(now).newestFirst, isFalse);
      expect(EventTimeFilter.thisWeek.rangeAt(now).newestFirst, isFalse);
    });

    test('Past Events end where All Upcoming begins', () {
      final range = EventTimeFilter.past.rangeAt(now);

      expect(range.startsAfter, isNull);
      expect(range.startsBefore, todayStart);
    });
  });

  group('events grouped under one header per day', () {
    final events = [
      _event(1, DateTime(2026, 10, 18, 10)),
      _event(2, DateTime(2026, 10, 18, 18)),
      _event(3, DateTime(2026, 10, 25, 10)),
    ];

    test('upcoming days run soonest first', () {
      final days = groupEventsByDay(events);

      expect(days.map((d) => d.day), [
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 25),
      ]);
      expect(days.first.events.map((e) => e.id), [1, 2]);
    });

    test('past days run most recent first, each day still in time order', () {
      final days = groupEventsByDay(events, mostRecentFirst: true);

      expect(days.map((d) => d.day), [
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 18),
      ]);
      expect(days.last.events.map((e) => e.id), [1, 2]);
    });

    test('no events, no days', () {
      expect(groupEventsByDay(const []), isEmpty);
    });
  });
}
