import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_permissions.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/event_detail_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';

ChurchEvent _event({
  int? createdBy = 7,
  RSVPStatus? rsvp,
  bool cancelled = false,
}) => ChurchEvent(
  id: 5,
  title: 'Youth Night',
  type: EventType.fellowship,
  startsAt: DateTime(2026, 10, 23, 18),
  endsAt: DateTime(2026, 10, 23, 20),
  description: 'Led by Sam',
  locationName: 'Hall B',
  pdfUrl: 'https://example.org/program.pdf',
  createdById: createdBy,
  isCancelled: cancelled,
  attendingCount: 3,
  myRsvp: rsvp,
);

class _FakeRepository extends EventsRepository {
  _FakeRepository() : super(dio: Dio());

  ChurchEvent? stored = _event();
  bool missing = false;
  bool failing = false;
  bool actionsFail = false;
  Completer<ChurchEvent>? slowRead;
  final calls = <String>[];
  EventDraft? lastUpdate;

  @override
  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async => [stored!];

  @override
  Future<ChurchEvent> getEvent(int id) async {
    calls.add('get');
    if (slowRead != null) return slowRead!.future;
    if (missing) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
        type: DioExceptionType.badResponse,
      );
    }
    if (failing) throw DioException(requestOptions: RequestOptions());
    return stored!;
  }

  @override
  Future<void> setRsvp({
    required int eventId,
    required String status,
    int guestCount = 0,
  }) async {
    if (actionsFail) throw DioException(requestOptions: RequestOptions());
    calls.add('rsvp:$status');
    stored = stored!.copyWith(myRsvp: RSVPStatus.fromString(status));
  }

  @override
  Future<void> withdrawRsvp(int eventId) async {
    calls.add('withdraw');
    stored = stored!.copyWith(clearRsvp: true);
  }

  @override
  Future<void> setCancelled(int id, bool cancelled) async =>
      calls.add('cancelled:$cancelled');

  @override
  Future<void> updateEvent(int id, EventDraft draft) async {
    calls.add('update');
    lastUpdate = draft;
  }

  @override
  Future<void> deleteEvent(int id) async => calls.add('delete');
}

void main() {
  group('who manages an Event', () {
    test('Pastors, Admins and Super Admins manage any Event', () {
      for (final role in [
        UserRole.pastor,
        UserRole.admin,
        UserRole.superAdmin,
      ]) {
        expect(
          canManageEvent(role: role, userId: 1, event: _event(createdBy: 7)),
          isTrue,
          reason: '$role',
        );
      }
    });

    test('a Youth Leader manages only the Events it posted', () {
      expect(
        canManageEvent(
          role: UserRole.youthLeader,
          userId: 7,
          event: _event(createdBy: 7),
        ),
        isTrue,
      );
      expect(
        canManageEvent(
          role: UserRole.youthLeader,
          userId: 8,
          event: _event(createdBy: 7),
        ),
        isFalse,
      );
      expect(
        canManageEvent(
          role: UserRole.youthLeader,
          userId: 7,
          event: _event(createdBy: null),
        ),
        isFalse,
      );
    });

    test('nobody else manages any, and a signed-out visitor manages none', () {
      for (final role in [
        UserRole.member,
        UserRole.elder,
        UserRole.treasurer,
      ]) {
        expect(
          canManageEvent(role: role, userId: 7, event: _event(createdBy: 7)),
          isFalse,
          reason: '$role',
        );
      }
      expect(
        canManageEvent(role: null, userId: null, event: _event()),
        isFalse,
      );
    });
  });

  group('editing an Event', () {
    test('the form starts from what is stored', () {
      final draft = EventDraft.fromEvent(_event());

      expect(draft.title, 'Youth Night');
      expect(draft.type, EventType.fellowship);
      expect(draft.startsAt, DateTime(2026, 10, 23, 18));
      expect(draft.endsAt, DateTime(2026, 10, 23, 20));
      expect(draft.description, 'Led by Sam');
      expect(draft.pdfUrl, 'https://example.org/program.pdf');
      expect(draft.repeatWeeklyForMonth, isFalse);
    });

    test(
      'a blank optional field is sent as null, so it clears what was stored',
      () {
        final json = EventDraft.fromEvent(_event())
            .copyWith(description: '', pdfUrl: '', clearEnd: true)
            .toUpdateJson();

        expect(json['description'], isNull);
        expect(json['pdf_url'], isNull);
        expect(json['end_at'], isNull);
        expect(json.containsKey('description'), isTrue);
        expect(json['title'], 'Youth Night');
        expect(json['type'], 'fellowship');
      },
    );
  });

  group('withdrawing an RSVP', () {
    test(
      'clears the member\'s answer, which copyWith(myRsvp: null) never did',
      () {
        final cleared = _event(rsvp: RSVPStatus.maybe)
            .copyWith(clearRsvp: true);

        expect(cleared.myRsvp, isNull);
      },
    );

    test('the calendar shows no answer after the member withdraws', () async {
      final repository = _FakeRepository()
        ..stored = _event(rsvp: RSVPStatus.attending);
      final bloc = EventsBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(const EventsFetchRequested());
      await bloc.stream.firstWhere((s) => s is EventsLoaded);

      bloc.add(const EventRsvpWithdrawn(eventId: 5));
      final state = await bloc.stream.firstWhere(
        (s) => s is EventsLoaded && s.events.first.myRsvp == null,
      );

      expect((state as EventsLoaded).events.first.attendingCount, 2);
    });
  });

  group('the detail screen\'s state', () {
    late _FakeRepository repository;
    late EventDetailBloc bloc;

    setUp(() {
      repository = _FakeRepository();
      bloc = EventDetailBloc(repository: repository);
      addTearDown(bloc.close);
    });

    /// Lets every handler that is waiting on the fake repository finish.
    Future<void> settle() => pumpEventQueue();

    test('starts out loading, then shows the Event it loaded by id', () async {
      expect(bloc.state.status, EventDetailStatus.loading);

      bloc.add(const EventDetailLoadRequested(5));
      await settle();

      expect(bloc.state.status, EventDetailStatus.loaded);
      expect(bloc.state.event?.title, 'Youth Night');
    });

    test('an Event that is gone reads as not found, not as an error', () async {
      repository.missing = true;

      bloc.add(const EventDetailLoadRequested(5));
      await settle();

      expect(bloc.state.status, EventDetailStatus.notFound);
    });

    test('a failed load can be retried', () async {
      repository.failing = true;
      bloc.add(const EventDetailLoadRequested(5));
      await settle();
      expect(bloc.state.status, EventDetailStatus.error);
      expect(bloc.state.errorMessage, isNotNull);

      repository.failing = false;
      bloc.add(const EventDetailLoadRequested(5));
      await settle();

      expect(bloc.state.status, EventDetailStatus.loaded);
    });

    test(
      'an RSVP is recorded, then the Event is read again for the true counts',
      () async {
        bloc.add(const EventDetailLoadRequested(5));
        await settle();

        bloc.add(const EventDetailRsvpSubmitted(RSVPStatus.attending));
        await settle();

        expect(repository.calls, ['get', 'rsvp:attending', 'get']);
        expect(bloc.state.event?.myRsvp, RSVPStatus.attending);

        bloc.add(const EventDetailRsvpWithdrawn());
        await settle();

        expect(bloc.state.event?.myRsvp, isNull);
      },
    );

    test('every failed action is reported, not only the first', () async {
      bloc.add(const EventDetailLoadRequested(5));
      await settle();
      repository.actionsFail = true;

      bloc.add(const EventDetailRsvpSubmitted(RSVPStatus.attending));
      await settle();
      expect(bloc.state.actionFailures, 1);

      bloc.add(const EventDetailRsvpSubmitted(RSVPStatus.maybe));
      await settle();

      expect(bloc.state.actionFailures, 2);
      expect(bloc.state.status, EventDetailStatus.loaded);
      expect(bloc.state.event?.title, 'Youth Night');
    });

    test('leaving the screen before the Event arrives is not an error', () async {
      repository.slowRead = Completer<ChurchEvent>();
      bloc.add(const EventDetailLoadRequested(5));
      await settle();

      await bloc.close();
      repository.slowRead!.complete(_event());
      await settle();

      expect(bloc.isClosed, isTrue);
    });

    test('cancelling and then deleting', () async {
      bloc.add(const EventDetailLoadRequested(5));
      await settle();

      bloc.add(const EventDetailCancelledChanged(true));
      await settle();
      bloc.add(const EventDetailDeleteRequested());
      await settle();

      expect(
        repository.calls,
        containsAllInOrder(['cancelled:true', 'delete']),
      );
      expect(bloc.state.status, EventDetailStatus.deleted);
    });

    test('saving an edit sends the form and shows the result', () async {
      bloc.add(const EventDetailLoadRequested(5));
      await settle();
      final draft = EventDraft.fromEvent(_event())
          .copyWith(title: 'Youth Night (moved)');

      bloc.add(EventDetailUpdated(draft));
      await settle();

      expect(repository.lastUpdate?.title, 'Youth Night (moved)');
      expect(bloc.state.status, EventDetailStatus.loaded);
    });
  });
}
