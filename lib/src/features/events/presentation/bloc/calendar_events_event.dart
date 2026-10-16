// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'calendar_events_bloc.dart';

abstract class CalendarEventsEvent extends Equatable {
  const CalendarEventsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the Events around the month that [focusedDay] is in.
class CalendarEventsLoadRequested extends CalendarEventsEvent {
  final DateTime focusedDay;
  const CalendarEventsLoadRequested(this.focusedDay);

  @override
  List<Object?> get props => [focusedDay];
}
