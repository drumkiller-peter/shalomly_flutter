/// The window of start times a calendar filter asks the backend for.
class EventRange {
  final DateTime? startsAfter;
  final DateTime? startsBefore;

  /// Ask for the latest first, so one page of past Events starts with last
  /// Sunday rather than with the oldest Event the church ever posted.
  final bool newestFirst;
  const EventRange({this.startsAfter, this.startsBefore, this.newestFirst = false});
}

/// The calendar's three filters. They are cut at the start of today, so an
/// Event earlier today is under [upcoming], never in neither list.
enum EventTimeFilter {
  upcoming('All Upcoming'),
  thisWeek('This Week'),
  past('Past Events');

  final String label;
  const EventTimeFilter(this.label);

  EventRange rangeAt(DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (this) {
      case EventTimeFilter.upcoming:
        return EventRange(startsAfter: todayStart);
      case EventTimeFilter.thisWeek:
        return EventRange(
          startsAfter: todayStart,
          startsBefore: DateTime(now.year, now.month, now.day + 7),
        );
      case EventTimeFilter.past:
        return EventRange(startsBefore: todayStart, newestFirst: true);
    }
  }
}
