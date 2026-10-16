import 'package:equatable/equatable.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

/// What a Group Post shows of the Event it points to. The backend reads it
/// from the Event each time, so it is always the Event's current details.
class EventSummary extends Equatable {
  final int id;
  final String title;
  final EventType type;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isAllDay;
  final String? locationName;
  final bool isCancelled;

  const EventSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.startsAt,
    this.endsAt,
    this.isAllDay = false,
    this.locationName,
    this.isCancelled = false,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    final end = json['end_at'] as String?;
    return EventSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      type: EventType.fromValue(json['type'] as String?),
      startsAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endsAt: end == null ? null : DateTime.parse(end).toLocal(),
      isAllDay: json['is_all_day'] as bool? ?? false,
      locationName: json['location_name'] as String?,
      isCancelled: json['is_cancelled'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, type, startsAt, endsAt, isAllDay, locationName, isCancelled];
}
