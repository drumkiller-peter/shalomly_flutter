import 'package:equatable/equatable.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

enum RSVPStatus {
  attending('attending', 'Attending'),
  maybe('maybe', 'Maybe'),
  declined('declined', 'Declined');

  final String value;
  final String label;
  const RSVPStatus(this.value, this.label);

  static RSVPStatus? fromString(String? val) {
    if (val == null) return null;
    return RSVPStatus.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => RSVPStatus.attending,
    );
  }
}

class ChurchEvent extends Equatable {
  final int id;
  final int tenantId;
  final String title;
  final EventType type;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isAllDay;
  final String? locationName;
  final String? address;
  final bool isCancelled;
  final String? pdfUrl;
  final String? imageUrl;
  final int? createdById;
  final int attendingCount;
  final int maybeCount;
  final int declinedCount;
  final RSVPStatus? myRsvp;

  const ChurchEvent({
    required this.id,
    this.tenantId = 1,
    required this.title,
    this.type = EventType.other,
    this.description,
    required this.startsAt,
    this.endsAt,
    this.isAllDay = false,
    this.locationName,
    this.address,
    this.isCancelled = false,
    this.pdfUrl,
    this.imageUrl,
    this.createdById,
    this.attendingCount = 0,
    this.maybeCount = 0,
    this.declinedCount = 0,
    this.myRsvp,
  });

  // Backward compatible accessors
  String? get location => locationName ?? address;
  int get rsvpCount => attendingCount;
  String? get userRsvp => myRsvp?.value;

  factory ChurchEvent.fromJson(Map<String, dynamic> json) {
    final startStr = (json['start_at'] ?? json['starts_at']) as String;
    final endStr = (json['end_at'] ?? json['ends_at']) as String?;

    final attending =
        (json['attending_count'] ?? json['rsvp_count']) as int? ?? 0;
    final maybe = json['maybe_count'] as int? ?? 0;
    final declined = json['declined_count'] as int? ?? 0;

    final rsvpVal = (json['my_rsvp'] ?? json['user_rsvp']) as String?;

    return ChurchEvent(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int? ?? 1,
      title: json['title'] as String,
      type: EventType.fromValue(json['type'] as String?),
      description: json['description'] as String?,
      // The API sends UTC; members read the calendar in their own time zone.
      startsAt: DateTime.parse(startStr).toLocal(),
      endsAt: endStr != null ? DateTime.parse(endStr).toLocal() : null,
      isAllDay: json['is_all_day'] as bool? ?? false,
      locationName: (json['location_name'] ?? json['location']) as String?,
      address: json['address'] as String?,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      pdfUrl: json['pdf_url'] as String?,
      imageUrl: json['image_url'] as String?,
      createdById: json['created_by_id'] as int?,
      attendingCount: attending,
      maybeCount: maybe,
      declinedCount: declined,
      myRsvp: RSVPStatus.fromString(rsvpVal),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'title': title,
      'type': type.value,
      'description': description,
      'start_at': startsAt.toUtc().toIso8601String(),
      'end_at': endsAt?.toUtc().toIso8601String(),
      'is_all_day': isAllDay,
      'location_name': locationName,
      'address': address,
      'is_cancelled': isCancelled,
      'pdf_url': pdfUrl,
      'image_url': imageUrl,
      'created_by_id': createdById,
      'attending_count': attendingCount,
      'maybe_count': maybeCount,
      'declined_count': declinedCount,
      'my_rsvp': myRsvp?.value,
    };
  }

  ChurchEvent copyWith({
    int? attendingCount,
    int? maybeCount,
    int? declinedCount,
    RSVPStatus? myRsvp,
    bool clearRsvp = false,
    int? rsvpCount,
    String? userRsvp,
  }) {
    return ChurchEvent(
      id: id,
      tenantId: tenantId,
      title: title,
      type: type,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      isAllDay: isAllDay,
      locationName: locationName,
      address: address,
      isCancelled: isCancelled,
      pdfUrl: pdfUrl,
      imageUrl: imageUrl,
      createdById: createdById,
      attendingCount: attendingCount ?? (rsvpCount ?? this.attendingCount),
      maybeCount: maybeCount ?? this.maybeCount,
      declinedCount: declinedCount ?? this.declinedCount,
      myRsvp: clearRsvp
          ? null
          : (myRsvp ??
                (userRsvp != null
                    ? RSVPStatus.fromString(userRsvp)
                    : this.myRsvp)),
    );
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    title,
    type,
    description,
    startsAt,
    endsAt,
    isAllDay,
    locationName,
    address,
    isCancelled,
    pdfUrl,
    imageUrl,
    createdById,
    attendingCount,
    maybeCount,
    declinedCount,
    myRsvp,
  ];
}
