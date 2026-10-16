import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

/// Something wrong with an Event form, before it is sent.
enum EventDraftProblem {
  missingTitle,
  missingType,
  missingStart,
  endBeforeStart,
  badPdfLink,
  badImageLink,
}

/// What a creator has filled in so far on the Event form.
///
/// Required: a title, a type, and a start date and time. Everything else is
/// optional. Who leads goes in the description; there is no separate field.
class EventDraft {
  final String title;
  final EventType? type;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String description;
  final String locationName;
  final String address;
  final String pdfUrl;
  final String imageUrl;

  /// "Repeat weekly for a month": post this Event and the same time on the
  /// next three weeks, each its own Event.
  final bool repeatWeeklyForMonth;

  const EventDraft({
    this.title = '',
    this.type,
    this.startsAt,
    this.endsAt,
    this.description = '',
    this.locationName = '',
    this.address = '',
    this.pdfUrl = '',
    this.imageUrl = '',
    this.repeatWeeklyForMonth = false,
  });

  /// The form for editing [event], starting from what is stored.
  factory EventDraft.fromEvent(ChurchEvent event) {
    return EventDraft(
      title: event.title,
      type: event.type,
      startsAt: event.startsAt,
      endsAt: event.endsAt,
      description: event.description ?? '',
      locationName: event.locationName ?? '',
      address: event.address ?? '',
      pdfUrl: event.pdfUrl ?? '',
      imageUrl: event.imageUrl ?? '',
    );
  }

  EventDraft copyWith({
    String? title,
    EventType? type,
    DateTime? startsAt,
    DateTime? endsAt,
    bool clearEnd = false,
    String? description,
    String? locationName,
    String? address,
    String? pdfUrl,
    String? imageUrl,
    bool? repeatWeeklyForMonth,
  }) {
    return EventDraft(
      title: title ?? this.title,
      type: type ?? this.type,
      startsAt: startsAt ?? this.startsAt,
      endsAt: clearEnd ? null : (endsAt ?? this.endsAt),
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      repeatWeeklyForMonth: repeatWeeklyForMonth ?? this.repeatWeeklyForMonth,
    );
  }

  /// Everything wrong with the form, in the order it appears; empty when it can be sent.
  List<EventDraftProblem> get problems {
    final start = startsAt;
    final end = endsAt;
    return [
      if (title.trim().length < 2) EventDraftProblem.missingTitle,
      if (type == null) EventDraftProblem.missingType,
      if (start == null) EventDraftProblem.missingStart,
      if (start != null && end != null && end.isBefore(start))
        EventDraftProblem.endBeforeStart,
      if (!_isBlankOrWebLink(pdfUrl)) EventDraftProblem.badPdfLink,
      if (!_isBlankOrWebLink(imageUrl)) EventDraftProblem.badImageLink,
    ];
  }

  /// This Event, then the same weekday and local wall-clock time on the next
  /// weeks, each a separate Event with everything copied. Calendar arithmetic,
  /// not "+ 7 days", so a daylight-saving change doesn't move the hour.
  List<EventDraft> weeklyCopies({int count = 4}) {
    final start = startsAt;
    if (!repeatWeeklyForMonth || start == null) return [this];
    DateTime weeksLater(DateTime t, int weeks) =>
        DateTime(t.year, t.month, t.day + 7 * weeks, t.hour, t.minute);
    return [
      for (var week = 0; week < count; week++)
        EventDraft(
          title: title,
          type: type,
          startsAt: weeksLater(start, week),
          endsAt: endsAt == null ? null : weeksLater(endsAt!, week),
          description: description,
          locationName: locationName,
          address: address,
          pdfUrl: pdfUrl,
          imageUrl: imageUrl,
        ),
    ];
  }

  /// The body of `POST /events`: only what was filled in, times in UTC. There
  /// is no group and no all-day flag.
  Map<String, dynamic> toCreateJson() {
    String? filled(String value) => value.trim().isEmpty ? null : value.trim();
    return {
      'title': title.trim(),
      'type': type!.value,
      'start_at': startsAt!.toUtc().toIso8601String(),
      'end_at': ?endsAt?.toUtc().toIso8601String(),
      'description': ?filled(description),
      'location_name': ?filled(locationName),
      'address': ?filled(address),
      'pdf_url': ?filled(pdfUrl),
      'image_url': ?filled(imageUrl),
    };
  }

  /// The body of `PATCH /events/{id}`. Every optional field is sent, blank ones
  /// as null, so clearing a field in the form clears it on the Event.
  Map<String, dynamic> toUpdateJson() {
    String? filled(String value) => value.trim().isEmpty ? null : value.trim();
    return {
      'title': title.trim(),
      'type': type!.value,
      'start_at': startsAt!.toUtc().toIso8601String(),
      'end_at': endsAt?.toUtc().toIso8601String(),
      'description': filled(description),
      'location_name': filled(locationName),
      'address': filled(address),
      'pdf_url': filled(pdfUrl),
      'image_url': filled(imageUrl),
    };
  }

  static bool _isBlankOrWebLink(String value) {
    final text = value.trim();
    if (text.isEmpty) return true;
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
