import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_time_filter.dart';

/// The Events of one calendar day, in time order.
class EventDay {
  final DateTime day;
  final List<ChurchEvent> events;
  const EventDay(this.day, this.events);
}

/// Groups Events under one header per day, in the member's time zone.
/// Days run soonest first, or most recent first for the Past filter; within a
/// day the Events keep their time order either way.
List<EventDay> groupEventsByDay(
  List<ChurchEvent> events, {
  bool mostRecentFirst = false,
}) {
  final sorted = [...events]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final byDay = <DateTime, List<ChurchEvent>>{};
  for (final event in sorted) {
    final local = event.startsAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    byDay.putIfAbsent(day, () => []).add(event);
  }
  final days = [for (final e in byDay.entries) EventDay(e.key, e.value)];
  return mostRecentFirst ? days.reversed.toList() : days;
}

/// The Events on [day] (whatever time of day it is), in time order. An Event
/// that runs over several days is on each of them; one that ends at midnight
/// does not spill onto the next day. Cancelled Events are not on the calendar.
List<ChurchEvent> eventsOnDay(List<ChurchEvent> events, DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final nextDay = DateTime(day.year, day.month, day.day + 1);
  final onDay = events.where((event) {
    if (event.isCancelled) return false;
    final start = event.startsAt;
    final end = event.endsAt;
    if (!start.isBefore(nextDay)) return false;
    if (end == null || !end.isAfter(start)) return !start.isBefore(dayStart);
    return end.isAfter(dayStart);
  }).toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return onDay;
}

/// The dates to load for the month [focusedDay] is in: the month and a week
/// either side, so the weeks shown at its edges have their markers too.
EventRange monthGridRange(DateTime focusedDay) {
  return EventRange(
    startsAfter: DateTime(focusedDay.year, focusedDay.month, 1 - 7),
    startsBefore: DateTime(focusedDay.year, focusedDay.month + 1, 1 + 7),
  );
}
