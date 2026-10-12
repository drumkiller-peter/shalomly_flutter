import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';

// Events
abstract class EventsEvent extends Equatable {
  const EventsEvent();
  @override
  List<Object?> get props => [];
}

class EventsFetchRequested extends EventsEvent {
  final DateTime? startsAfter;
  final DateTime? startsBefore;
  final int? groupId;
  const EventsFetchRequested({this.startsAfter, this.startsBefore, this.groupId});
  @override
  List<Object?> get props => [startsAfter, startsBefore, groupId];
}

class EventCreateRequested extends EventsEvent {
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? locationName;
  final String? address;
  final int? groupId;
  const EventCreateRequested({
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    this.locationName,
    this.address,
    this.groupId,
  });
  @override
  List<Object?> get props => [title, description, startsAt, endsAt, locationName, address, groupId];
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
  const EventsLoaded(this.events, {this.rsvpError});
  @override
  List<Object?> get props => [events, rsvpError];
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
    emit(const EventsLoading());
    try {
      final events = await repository.getEvents(
        startsAfter: event.startsAfter,
        startsBefore: event.startsBefore,
        groupId: event.groupId,
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
    try {
      await repository.createEvent(
        title: event.title,
        description: event.description,
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        locationName: event.locationName,
        address: event.address,
        groupId: event.groupId,
      );
      add(const EventsFetchRequested());
    } catch (e) {
      emit(EventsError(e.toString()));
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
        emit(EventsLoaded(
          currentEvents,
          rsvpError: 'Unable to record RSVP response. Please try again.',
        ));
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
            myRsvp: null,
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
        emit(EventsLoaded(
          currentEvents,
          rsvpError: 'Unable to withdraw RSVP. Please try again.',
        ));
      }
    }
  }
}
