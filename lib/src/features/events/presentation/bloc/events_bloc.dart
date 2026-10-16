import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';

// Events
abstract class EventsEvent extends Equatable {
  const EventsEvent();
  @override
  List<Object?> get props => [];
}

class EventsFetchRequested extends EventsEvent {
  final DateTime? startsAfter;
  final DateTime? startsBefore;
  final bool newestFirst;
  const EventsFetchRequested({
    this.startsAfter,
    this.startsBefore,
    this.newestFirst = false,
  });
  @override
  List<Object?> get props => [startsAfter, startsBefore, newestFirst];
}

/// Post the form's Event, and its weekly copies when it repeats.
///
/// [shareWith] are the Groups to share it with; a repeating Event is shared
/// once, from its first week.
class EventCreateRequested extends EventsEvent {
  final EventDraft draft;
  final List<Group> shareWith;
  const EventCreateRequested(this.draft, {this.shareWith = const []});
  @override
  List<Object?> get props => [draft, shareWith];
}

class EventRsvpSubmitted extends EventsEvent {
  final int eventId;
  final RSVPStatus status;
  final int guestCount;
  const EventRsvpSubmitted({
    required this.eventId,
    required this.status,
    this.guestCount = 0,
  });
  @override
  List<Object?> get props => [eventId, status, guestCount];
}

class EventRsvpWithdrawn extends EventsEvent {
  final int eventId;
  const EventRsvpWithdrawn({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}

// States
abstract class EventsState extends Equatable {
  const EventsState();
  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {
  const EventsInitial();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  final List<ChurchEvent> events;
  final String? rsvpError;

  /// After posting: how many Events went through and how many did not.
  final int? postedCount;
  final int? postFailedCount;

  /// Names of the Groups the Event could not be shared with.
  final List<String> shareFailedGroups;
  const EventsLoaded(
    this.events, {
    this.rsvpError,
    this.postedCount,
    this.postFailedCount,
    this.shareFailedGroups = const [],
  });
  @override
  List<Object?> get props => [
    events,
    rsvpError,
    postedCount,
    postFailedCount,
    shareFailedGroups,
  ];
}

class EventsError extends EventsState {
  final String message;
  const EventsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository repository;

  /// Counts fetches, so an older fetch that answers late doesn't overwrite a
  /// newer one (say, the Events screen's filtered list).
  int _latestFetch = 0;

  /// The list the member was last looking at, to show again after posting.
  EventsFetchRequested _lastRequest = const EventsFetchRequested();

  EventsBloc({required this.repository}) : super(const EventsInitial()) {
    on<EventsFetchRequested>(_onFetchRequested);
    on<EventCreateRequested>(_onCreateRequested);
    on<EventRsvpSubmitted>(_onRsvpSubmitted);
    on<EventRsvpWithdrawn>(_onRsvpWithdrawn);
  }

  Future<void> _onFetchRequested(
    EventsFetchRequested event,
    Emitter<EventsState> emit,
  ) async {
    final fetch = ++_latestFetch;
    _lastRequest = event;
    emit(const EventsLoading());
    try {
      final events = await repository.getEvents(
        startsAfter: event.startsAfter,
        startsBefore: event.startsBefore,
        newestFirst: event.newestFirst,
      );
      if (fetch == _latestFetch) emit(EventsLoaded(events));
    } catch (e) {
      if (fetch == _latestFetch) emit(EventsError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    EventCreateRequested event,
    Emitter<EventsState> emit,
  ) async {
    var posted = 0;
    var failed = 0;
    // A repeating Event is shared once: its earliest week that was posted.
    ChurchEvent? first;
    for (final draft in event.draft.weeklyCopies()) {
      try {
        final created = await repository.createEvent(draft);
        first ??= created;
        posted++;
      } catch (_) {
        failed++;
      }
    }
    final shareFailed = <String>[];
    for (final group in event.shareWith) {
      try {
        if (first == null) throw StateError('The Event was not posted');
        await repository.shareWithGroup(eventId: first.id, groupId: group.id);
      } catch (_) {
        shareFailed.add(group.name);
      }
    }
    final fetch = ++_latestFetch;
    try {
      final events = await repository.getEvents(
        startsAfter: _lastRequest.startsAfter,
        startsBefore: _lastRequest.startsBefore,
        newestFirst: _lastRequest.newestFirst,
      );
      if (fetch == _latestFetch) {
        emit(
          EventsLoaded(
            events,
            postedCount: posted,
            postFailedCount: failed,
            shareFailedGroups: shareFailed,
          ),
        );
      }
    } catch (e) {
      if (fetch == _latestFetch) emit(EventsError(e.toString()));
    }
  }

  Future<void> _onRsvpSubmitted(
    EventRsvpSubmitted event,
    Emitter<EventsState> emit,
  ) async {
    if (state is EventsLoaded) {
      final currentEvents = (state as EventsLoaded).events;
      final updated = currentEvents.map((e) {
        if (e.id == event.eventId) {
          final wasAttending = e.myRsvp == RSVPStatus.attending;
          final wasMaybe = e.myRsvp == RSVPStatus.maybe;
          final wasDeclined = e.myRsvp == RSVPStatus.declined;

          var attending = e.attendingCount;
          var maybe = e.maybeCount;
          var declined = e.declinedCount;

          if (wasAttending) attending--;
          if (wasMaybe) maybe--;
          if (wasDeclined) declined--;

          if (event.status == RSVPStatus.attending) attending++;
          if (event.status == RSVPStatus.maybe) maybe++;
          if (event.status == RSVPStatus.declined) declined++;

          return e.copyWith(
            myRsvp: event.status,
            attendingCount: attending < 0 ? 0 : attending,
            maybeCount: maybe < 0 ? 0 : maybe,
            declinedCount: declined < 0 ? 0 : declined,
          );
        }
        return e;
      }).toList();

      emit(EventsLoaded(updated));
      try {
        await repository.setRsvp(
          eventId: event.eventId,
          status: event.status.value,
          guestCount: event.guestCount,
        );
      } catch (e) {
        // Revert to original events and alert user of failure
        emit(
          EventsLoaded(
            currentEvents,
            rsvpError: 'Unable to record RSVP response. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> _onRsvpWithdrawn(
    EventRsvpWithdrawn event,
    Emitter<EventsState> emit,
  ) async {
    if (state is EventsLoaded) {
      final currentEvents = (state as EventsLoaded).events;
      final updated = currentEvents.map((e) {
        if (e.id == event.eventId) {
          var attending = e.attendingCount;
          var maybe = e.maybeCount;
          var declined = e.declinedCount;

          if (e.myRsvp == RSVPStatus.attending) attending--;
          if (e.myRsvp == RSVPStatus.maybe) maybe--;
          if (e.myRsvp == RSVPStatus.declined) declined--;

          return e.copyWith(
            clearRsvp: true,
            attendingCount: attending < 0 ? 0 : attending,
            maybeCount: maybe < 0 ? 0 : maybe,
            declinedCount: declined < 0 ? 0 : declined,
          );
        }
        return e;
      }).toList();

      emit(EventsLoaded(updated));
      try {
        await repository.withdrawRsvp(event.eventId);
      } catch (e) {
        // Revert to original events and alert user of failure
        emit(
          EventsLoaded(
            currentEvents,
            rsvpError: 'Unable to withdraw RSVP. Please try again.',
          ),
        );
      }
    }
  }
}
