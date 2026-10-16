// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'event_detail_bloc.dart';

enum EventDetailStatus {
  loading,
  loaded,

  /// The Event was deleted, or was never on this church's calendar.
  notFound,
  error,

  /// The member just deleted the Event; the screen closes.
  deleted,
}

class EventDetailState extends Equatable {
  final EventDetailStatus status;
  final ChurchEvent? event;
  final String? errorMessage;

  /// How many changes (an RSVP, an edit, a cancel, a delete) have failed. It
  /// only ever grows, so a second failure in a row is a new state and the
  /// screen reports it too, instead of it being dropped as equal to the first.
  final int actionFailures;

  const EventDetailState({
    this.status = EventDetailStatus.loading,
    this.event,
    this.errorMessage,
    this.actionFailures = 0,
  });

  EventDetailState copyWith({
    EventDetailStatus? status,
    ChurchEvent? event,
    String? errorMessage,
    int? actionFailures,
  }) {
    return EventDetailState(
      status: status ?? this.status,
      event: event ?? this.event,
      errorMessage: errorMessage ?? this.errorMessage,
      actionFailures: actionFailures ?? this.actionFailures,
    );
  }

  @override
  List<Object?> get props => [status, event, errorMessage, actionFailures];
}
