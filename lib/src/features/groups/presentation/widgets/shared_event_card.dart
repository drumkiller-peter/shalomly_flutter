import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/events/domain/event_summary.dart';
import 'package:shalomly_app/src/features/events/presentation/event_type_style.dart';

/// The Event a Group Post shares, with its current date, time and place. It
/// opens the Event.
class SharedEventCard extends StatelessWidget {
  final EventSummary event;
  const SharedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    final when = '${DateFormat('EEE d MMM').format(event.startsAt)} · ${DateFormat('h:mm a').format(event.startsAt)}';
    final place = event.locationName;
    return Ink(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRoutes.eventDetail(event.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(event.type.icon, size: 26, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTheme.serif(fontSize: 17, fontWeight: FontWeight.w700, color: colors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place == null || place.isEmpty ? when : '$when · $place',
                      style: TextStyle(fontSize: 14, color: colors.textMuted),
                    ),
                    if (event.isCancelled)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          TranslationString.eventCardCancelled.tr(),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.error),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
