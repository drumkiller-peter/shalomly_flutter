// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'event_detail_bloc.dart';

abstract class EventDetailEvent extends Equatable {
  const EventDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Open an Event by id, or read it again (also how a failed load is retried).
class EventDetailLoadRequested extends EventDetailEvent {
  final int eventId;
  const EventDetailLoadRequested(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class EventDetailRsvpSubmitted extends EventDetailEvent {
  final RSVPStatus status;
  const EventDetailRsvpSubmitted(this.status);

  @override
  List<Object?> get props => [status];
}

class EventDetailRsvpWithdrawn extends EventDetailEvent {
  const EventDetailRsvpWithdrawn();
}

/// Call the Event off, or put it back on the calendar.
class EventDetailCancelledChanged extends EventDetailEvent {
  final bool cancelled;
  const EventDetailCancelledChanged(this.cancelled);

  @override
  List<Object?> get props => [cancelled];
}

/// Save the edit form.
class EventDetailUpdated extends EventDetailEvent {
  final EventDraft draft;
  const EventDetailUpdated(this.draft);

  @override
  List<Object?> get props => [draft];
}

class EventDetailDeleteRequested extends EventDetailEvent {
  const EventDetailDeleteRequested();
}
