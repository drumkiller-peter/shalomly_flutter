import 'package:shalomly_app/src/features/events/domain/event.dart';

/// How long a worship service with no end time is taken to last.
const Duration assumedServiceLength = Duration(hours: 2);

/// The worship Event Home shows: the first one, in time order, that hasn't
/// finished yet, so a service in progress still shows its order of service.
/// Cancelled services are skipped.
ChurchEvent? pickNextWorship(List<ChurchEvent> worship, DateTime now) {
  final sorted = [...worship]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  for (final event in sorted) {
    if (event.isCancelled) continue;
    final end = event.endsAt ?? event.startsAt.add(assumedServiceLength);
    if (end.isAfter(now)) return event;
  }
  return null;
}

extension HomeWorshipEvent on ChurchEvent {
  /// Whether there is anything to read for the service: its text or a PDF.
  bool get hasOrderOfService =>
      (description?.trim().isNotEmpty ?? false) || (pdfUrl?.trim().isNotEmpty ?? false);
}
