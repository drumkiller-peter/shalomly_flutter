/// What kind of thing an Event is: one fixed list for every church, matching
/// the backend's Event Types. It says what an Event is, never who it is for.
enum EventType {
  worship('worship'),
  fellowship('fellowship'),
  conference('conference'),
  bibleStudy('bible_study'),
  prayerMeeting('prayer_meeting'),
  outreach('outreach'),
  celebration('celebration'),
  notice('notice'),
  other('other');

  /// The value the API sends and expects.
  final String value;
  const EventType(this.value);

  /// A type this app doesn't know (a newer backend) reads as [other].
  static EventType fromValue(String? value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EventType.other,
    );
  }
}
