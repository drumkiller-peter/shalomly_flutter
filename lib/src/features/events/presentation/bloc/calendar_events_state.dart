// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'calendar_events_bloc.dart';

enum CalendarEventsStatus { initial, loading, loaded, error }

class CalendarEventsState extends Equatable {
  final CalendarEventsStatus status;
  final List<ChurchEvent> events;
  final String? errorMessage;

  const CalendarEventsState({
    this.status = CalendarEventsStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  CalendarEventsState copyWith({
    CalendarEventsStatus? status,
    List<ChurchEvent>? events,
    String? errorMessage,
  }) {
    return CalendarEventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
}
