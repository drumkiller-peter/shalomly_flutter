import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

/// How each Event Type looks: one label and one icon, defined here only.
extension EventTypeStyle on EventType {
  String get label => switch (this) {
    EventType.worship => TranslationString.eventTypeWorship,
    EventType.fellowship => TranslationString.eventTypeFellowship,
    EventType.conference => TranslationString.eventTypeConference,
    EventType.bibleStudy => TranslationString.eventTypeBibleStudy,
    EventType.prayerMeeting => TranslationString.eventTypePrayerMeeting,
    EventType.outreach => TranslationString.eventTypeOutreach,
    EventType.celebration => TranslationString.eventTypeCelebration,
    EventType.notice => TranslationString.eventTypeNotice,
    EventType.other => TranslationString.eventTypeOther,
  }.tr();

  IconData get icon => switch (this) {
    EventType.worship => Icons.church_rounded,
    EventType.fellowship => Icons.groups_rounded,
    EventType.conference => Icons.record_voice_over_rounded,
    EventType.bibleStudy => Icons.menu_book_rounded,
    EventType.prayerMeeting => Icons.self_improvement_rounded,
    EventType.outreach => Icons.volunteer_activism_rounded,
    EventType.celebration => Icons.celebration_rounded,
    EventType.notice => Icons.campaign_rounded,
    EventType.other => Icons.event_rounded,
  };
}
