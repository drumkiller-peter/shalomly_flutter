import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';
import 'package:shalomly_app/src/features/events/domain/share_targets.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';

Group _group(int id, String name, {bool leader = false, bool archived = false}) => Group(
      id: id,
      tenantId: 1,
      name: name,
      groupType: GroupType.other,
      isOpen: true,
      isArchived: archived,
      memberCount: 4,
      isMember: true,
      isLeader: leader,
      createdAt: DateTime(2026),
    );

Map<String, dynamic> _post({Object? body = 'Join us', int? eventId = 5, Object? event}) => {
      'id': 1,
      'group_id': 2,
      'author_id': 3,
      'author_name': 'Pastor Ram',
      'body': body,
      'event_id': eventId,
      'event': event,
      'created_at': '2026-10-20T08:00:00Z',
      'updated_at': '2026-10-20T08:00:00Z',
    };

class _FakeRepository extends EventsRepository {
  _FakeRepository() : super(dio: Dio());

  final created = <EventDraft>[];
  final shared = <(int, int)>[];
  Set<int> failingGroups = {};
  bool createFails = false;
  Set<int> failingCreateNumbers = {};

  @override
  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async => const [];

  @override
  Future<ChurchEvent> createEvent(EventDraft draft) async {
    created.add(draft);
    if (createFails || failingCreateNumbers.contains(created.length)) {
      throw DioException(requestOptions: RequestOptions());
    }
    return ChurchEvent(id: 100 + created.length, title: draft.title, startsAt: draft.startsAt!);
  }

  @override
  Future<void> shareWithGroup({required int eventId, required int groupId}) async {
    if (failingGroups.contains(groupId)) throw DioException(requestOptions: RequestOptions());
    shared.add((eventId, groupId));
  }
}

EventDraft _weekly() => EventDraft(
      title: 'Youth Night',
      type: EventType.fellowship,
      startsAt: DateTime(2026, 10, 23, 18),
      repeatWeeklyForMonth: true,
    );

Future<EventsLoaded> _posted(EventsBloc bloc) async =>
    (await bloc.stream.firstWhere((s) => s is EventsLoaded && s.postedCount != null)) as EventsLoaded;

void main() {
  group('a Group Post that points to an Event', () {
    test('carries the Event\'s current details', () {
      final post = GroupPost.fromJson(_post(event: {
        'id': 5,
        'title': 'Youth Night',
        'type': 'fellowship',
        'start_at': '2026-10-23T18:00:00Z',
        'end_at': null,
        'is_all_day': false,
        'location_name': 'Hall B',
        'is_cancelled': true,
      }));

      expect(post.eventId, 5);
      expect(post.event?.title, 'Youth Night');
      expect(post.event?.type, EventType.fellowship);
      expect(post.event?.locationName, 'Hall B');
      expect(post.event?.isCancelled, isTrue);
    });

    test('keeps its message when the Event was deleted', () {
      final post = GroupPost.fromJson(_post(event: null));

      expect(post.eventId, 5);
      expect(post.event, isNull);
      expect(post.body, 'Join us');
    });

    test('may be only an Event, with no message', () {
      final post = GroupPost.fromJson(_post(body: null, event: null));

      expect(post.body, isNull);
    });
  });

  group('which Groups an Event can be shared with', () {
    final groups = [
      _group(1, 'Choir'),
      _group(2, 'Youth', leader: true),
      _group(3, 'Old Group', leader: true, archived: true),
    ];

    test('Pastors and Admins: every active Group', () {
      for (final role in [UserRole.pastor, UserRole.admin, UserRole.superAdmin]) {
        expect(shareableGroups(groups, role).map((g) => g.id), [1, 2], reason: '$role');
      }
    });

    test('a Youth Leader: only the Groups it leads', () {
      expect(shareableGroups(groups, UserRole.youthLeader).map((g) => g.id), [2]);
    });

    test('nobody else, and nobody signed out', () {
      expect(shareableGroups(groups, UserRole.member), isEmpty);
      expect(shareableGroups(groups, null), isEmpty);
    });
  });

  group('posting with Groups chosen', () {
    late _FakeRepository repository;
    late EventsBloc bloc;
    final youth = _group(2, 'Youth');
    final choir = _group(1, 'Choir');

    setUp(() {
      repository = _FakeRepository();
      bloc = EventsBloc(repository: repository);
      addTearDown(bloc.close);
    });

    test('a repeated Event is shared once, from its first week', () async {
      bloc.add(EventCreateRequested(_weekly(), shareWith: [youth, choir]));
      final result = await _posted(bloc);

      expect(repository.created, hasLength(4));
      expect(repository.shared, [(101, 2), (101, 1)]);
      expect(result.shareFailedGroups, isEmpty);
    });

    test('a Group that can\'t be reached is named, and the Event stays posted', () async {
      repository.failingGroups = {2};

      bloc.add(EventCreateRequested(_weekly().copyWith(repeatWeeklyForMonth: false), shareWith: [youth, choir]));
      final result = await _posted(bloc);

      expect(result.postedCount, 1);
      expect(result.shareFailedGroups, ['Youth']);
      expect(repository.shared, [(101, 1)]);
    });

    test('when week one fails but later weeks go through, the first one that did is shared', () async {
      repository.failingCreateNumbers = {1};

      bloc.add(EventCreateRequested(_weekly(), shareWith: [youth]));
      final result = await _posted(bloc);

      expect(result.postedCount, 3);
      expect(result.postFailedCount, 1);
      expect(repository.shared, [(102, 2)]);
      expect(result.shareFailedGroups, isEmpty);
    });

    test('nothing is shared when no Event could be posted', () async {
      repository.createFails = true;

      bloc.add(EventCreateRequested(_weekly(), shareWith: [youth]));
      final result = await _posted(bloc);

      expect(repository.shared, isEmpty);
      expect(result.shareFailedGroups, ['Youth']);
    });

    test('with no Groups chosen nothing is shared', () async {
      bloc.add(EventCreateRequested(_weekly()));
      await _posted(bloc);

      expect(repository.shared, isEmpty);
    });
  });
}
