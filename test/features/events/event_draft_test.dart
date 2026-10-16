import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

EventDraft _valid() => EventDraft(
  title: 'Sunday Worship',
  type: EventType.worship,
  startsAt: DateTime(2026, 10, 25, 10),
);

void main() {
  group('what a creator must fill in', () {
    test('a title, a type and a start date and time are enough', () {
      expect(_valid().problems, isEmpty);
    });

    test('an empty form says everything that is missing', () {
      expect(const EventDraft().problems, [
        EventDraftProblem.missingTitle,
        EventDraftProblem.missingType,
        EventDraftProblem.missingStart,
      ]);
    });

    test('the title needs two letters, as the backend does', () {
      expect(_valid().copyWith(title: ' A ').problems, [
        EventDraftProblem.missingTitle,
      ]);
    });

    test('an end before the start is refused', () {
      final draft = _valid().copyWith(endsAt: DateTime(2026, 10, 25, 9));

      expect(draft.problems, [EventDraftProblem.endBeforeStart]);
    });

    test('links must be web addresses, and blank links are fine', () {
      expect(_valid().copyWith(pdfUrl: 'order of service').problems, [
        EventDraftProblem.badPdfLink,
      ]);
      expect(_valid().copyWith(imageUrl: 'ftp://x.org/a.png').problems, [
        EventDraftProblem.badImageLink,
      ]);
      expect(
        _valid()
            .copyWith(pdfUrl: '  ', imageUrl: 'https://example.org/a.jpg')
            .problems,
        isEmpty,
      );
    });
  });

  group('what is sent to the API', () {
    test(
      'only what was filled in, with times in UTC and no group or all-day flag',
      () {
        final json = _valid()
            .copyWith(
              endsAt: DateTime(2026, 10, 25, 12),
              description: ' Led by Pastor Ram ',
              locationName: 'Main Hall',
              pdfUrl: 'https://example.org/order.pdf',
            )
            .toCreateJson();

        expect(json, {
          'title': 'Sunday Worship',
          'type': 'worship',
          'start_at': DateTime(2026, 10, 25, 10).toUtc().toIso8601String(),
          'end_at': DateTime(2026, 10, 25, 12).toUtc().toIso8601String(),
          'description': 'Led by Pastor Ram',
          'location_name': 'Main Hall',
          'pdf_url': 'https://example.org/order.pdf',
        });
      },
    );
  });

  group('repeat weekly for a month', () {
    test(
      'four Events, a week apart, at the same time, across a month boundary',
      () {
        final copies = _valid()
            .copyWith(
              endsAt: DateTime(2026, 10, 25, 12),
              repeatWeeklyForMonth: true,
            )
            .weeklyCopies();

        expect(copies.map((c) => c.startsAt), [
          DateTime(2026, 10, 25, 10),
          DateTime(2026, 11, 1, 10),
          DateTime(2026, 11, 8, 10),
          DateTime(2026, 11, 15, 10),
        ]);
        expect(copies.map((c) => c.endsAt), [
          DateTime(2026, 10, 25, 12),
          DateTime(2026, 11, 1, 12),
          DateTime(2026, 11, 8, 12),
          DateTime(2026, 11, 15, 12),
        ]);
        expect(
          copies.every((c) => c.startsAt!.weekday == DateTime.sunday),
          isTrue,
        );
      },
    );

    test('every copy carries everything, and none repeats again', () {
      final copies = _valid()
          .copyWith(
            description: 'Led by Pastor Ram',
            pdfUrl: 'https://example.org/order.pdf',
            imageUrl: 'https://example.org/banner.jpg',
            repeatWeeklyForMonth: true,
          )
          .weeklyCopies();

      for (final copy in copies) {
        expect(copy.title, 'Sunday Worship');
        expect(copy.type, EventType.worship);
        expect(copy.description, 'Led by Pastor Ram');
        expect(copy.pdfUrl, 'https://example.org/order.pdf');
        expect(copy.imageUrl, 'https://example.org/banner.jpg');
        expect(copy.repeatWeeklyForMonth, isFalse);
      }
    });

    test('without the switch it is one Event', () {
      expect(_valid().weeklyCopies(), hasLength(1));
    });
  });
}
