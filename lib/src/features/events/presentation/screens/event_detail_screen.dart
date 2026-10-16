import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_permissions.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/event_detail_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/event_type_style.dart';
import 'package:shalomly_app/src/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// One Event, opened by id: from the calendar, Home, or a Group Post.
class EventDetailScreen extends StatelessWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EventDetailBloc(repository: context.read<EventsRepository>())
            ..add(EventDetailLoadRequested(eventId)),
      child: Scaffold(
        appBar: AppBar(title: Text(TranslationString.eventDetailTitle.tr())),
        body: SafeArea(
          child: BlocConsumer<EventDetailBloc, EventDetailState>(
            // Only when the Event was just deleted, or another change failed.
            listenWhen: (previous, current) =>
                current.actionFailures != previous.actionFailures ||
                (current.status == EventDetailStatus.deleted &&
                    previous.status != EventDetailStatus.deleted),
            listener: (context, state) {
              if (state.status == EventDetailStatus.deleted) {
                context.pop();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationString.eventActionFailed.tr()),
                  backgroundColor: context.churchColors.error,
                ),
              );
            },
            builder: (context, state) {
              final event = state.event;
              return switch (state.status) {
                EventDetailStatus.loading ||
                EventDetailStatus.deleted => const Center(
                  child: CircularProgressIndicator(),
                ),
                EventDetailStatus.notFound => _Message(
                  icon: Icons.event_busy_rounded,
                  title: TranslationString.eventNotFound.tr(),
                ),
                EventDetailStatus.error => _Message(
                  icon: Icons.error_outline_rounded,
                  title: TranslationString.eventLoadError.tr(),
                  detail: state.errorMessage,
                  onRetry: () => context.read<EventDetailBloc>().add(
                    EventDetailLoadRequested(eventId),
                  ),
                ),
                EventDetailStatus.loaded =>
                  event == null
                      ? const SizedBox.shrink()
                      : _EventBody(event: event),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onRetry;
  const _Message({
    required this.icon,
    required this.title,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                onPressed: onRetry,
                child: Text(TranslationString.eventRetry.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventBody extends StatelessWidget {
  final ChurchEvent event;
  const _EventBody({required this.event});

  /// "Friday, 23 October 2026 · 6:00 PM – 8:00 PM", or both dates when it spans days.
  String _when() {
    final dayFormat = DateFormat('EEEE, d MMMM yyyy');
    final timeFormat = DateFormat('h:mm a');
    final start = event.startsAt;
    final end = event.endsAt;
    if (end == null) {
      return '${dayFormat.format(start)} · ${timeFormat.format(start)}';
    }
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${dayFormat.format(start)} · ${timeFormat.format(start)} – ${timeFormat.format(end)}';
    }
    return '${dayFormat.format(start)} · ${timeFormat.format(start)}\n'
        '– ${dayFormat.format(end)} · ${timeFormat.format(end)}';
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    final place = [
      event.locationName,
      event.address,
    ].whereType<String>().where((t) => t.isNotEmpty);
    final description = event.description;
    final pdf = event.pdfUrl;
    final image = event.imageUrl;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (event.isCancelled)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy_rounded, color: colors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    TranslationString.eventCancelledBanner.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(event.type.icon, size: 18, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  event.type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          event.title,
          style: AppTheme.serif(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.schedule_rounded, text: _when()),
        if (place.isNotEmpty)
          _InfoRow(icon: Icons.location_on_outlined, text: place.join('\n')),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 17, height: 1.5, color: colors.text),
          ),
        ],
        if (image != null && image.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
              placeholder: (_, _) => const SizedBox(height: 160),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        if (pdf != null && pdf.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(
              TranslationString.eventOpenPdf.tr(),
              style: const TextStyle(fontSize: 16),
            ),
            onPressed: () => _openPdf(pdf),
          ),
        ],
        const SizedBox(height: 20),
        _RsvpSection(event: event),
        _ManageSection(event: event),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 17, height: 1.4, color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _RsvpSection extends StatelessWidget {
  final ChurchEvent event;
  const _RsvpSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    final signedIn = context.watch<AuthBloc>().state is Authenticated;
    final bloc = context.read<EventDetailBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sanctuaryCard(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationString.eventAttendingCount.tr(
              args: ['${event.attendingCount}'],
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          if (!signedIn)
            Text(
              TranslationString.eventRsvpSignIn.tr(),
              style: TextStyle(fontSize: 16, color: colors.textMuted),
            )
          else if (!event.isCancelled) ...[
            Text(
              TranslationString.eventRsvpHeading.tr(),
              style: AppTheme.serif(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in RSVPStatus.values)
                  ChoiceChip(
                    label: Text(
                      status.label,
                      style: const TextStyle(fontSize: 16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    selected: event.myRsvp == status,
                    onSelected: (_) => bloc.add(EventDetailRsvpSubmitted(status)),
                  ),
              ],
            ),
            if (event.myRsvp != null)
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => bloc.add(const EventDetailRsvpWithdrawn()),
                child: Text(
                  TranslationString.eventRsvpWithdraw.tr(),
                  style: TextStyle(color: colors.textMuted, fontSize: 15),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Edit, Cancel and Delete: shown only to whoever may manage this Event.
class _ManageSection extends StatelessWidget {
  final ChurchEvent event;
  const _ManageSection({required this.event});

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<EventDetailBloc>();
    final result = await showEventFormSheet(
      context,
      initial: EventDraft.fromEvent(event),
    );
    if (result != null) bloc.add(EventDetailUpdated(result.draft));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<EventDetailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(TranslationString.eventDeleteConfirmTitle.tr()),
        content: Text(
          TranslationString.eventDeleteConfirmBody.tr(args: [event.title]),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(TranslationString.eventKeep.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: dialogContext.churchColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(TranslationString.eventDeleteAction.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(const EventDetailDeleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth is Authenticated ? auth.user : null;
    if (!canManageEvent(role: user?.role, userId: user?.id, event: event)) {
      return const SizedBox.shrink();
    }
    final colors = context.churchColors;
    final bloc = context.read<EventDetailBloc>();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: colors.border),
          const SizedBox(height: 8),
          Text(
            TranslationString.eventManageHeading.tr(),
            style: AppTheme.serif(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _edit(context),
            child: Text(
              TranslationString.eventEditAction.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () =>
                bloc.add(EventDetailCancelledChanged(!event.isCancelled)),
            child: Text(
              (event.isCancelled
                      ? TranslationString.eventReinstateAction
                      : TranslationString.eventCancelAction)
                  .tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: colors.error,
            ),
            onPressed: () => _confirmDelete(context),
            child: Text(
              TranslationString.eventDeleteAction.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
