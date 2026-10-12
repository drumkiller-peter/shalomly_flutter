import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/widgets/member_session_scope.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';

enum EventTimeFilter {
  upcoming('All Upcoming'),
  thisWeek('This Week'),
  past('Past Events');

  final String label;
  const EventTimeFilter(this.label);
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventTimeFilter _selectedFilter = EventTimeFilter.upcoming;
  int? _sessionGeneration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On first build, and again whenever someone else signs in: the new
    // member's RSVPs, under this screen's filter.
    final generation = MemberSessionScope.generationOf(context);
    if (generation != _sessionGeneration) {
      _sessionGeneration = generation;
      _triggerFilterFetch(_selectedFilter);
    }
  }

  void _triggerFilterFetch(EventTimeFilter filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekEnd = todayStart.add(const Duration(days: 7));

    DateTime? startsAfter;
    DateTime? startsBefore;

    switch (filter) {
      case EventTimeFilter.upcoming:
        startsAfter = now;
        break;
      case EventTimeFilter.thisWeek:
        startsAfter = todayStart;
        startsBefore = weekEnd;
        break;
      case EventTimeFilter.past:
        startsBefore = todayStart;
        break;
    }

    context.read<EventsBloc>().add(EventsFetchRequested(
          startsAfter: startsAfter,
          startsBefore: startsBefore,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final canPost = authState is Authenticated && authState.user.role.canPostChurchEvents;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Church Calendar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _triggerFilterFetch(_selectedFilter),
              ),
            ],
          ),
          floatingActionButton: canPost
              ? FloatingActionButton.extended(
                  backgroundColor: context.churchColors.primary,
                  foregroundColor: context.churchColors.onPrimary,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Post Church Event'),
                  onPressed: () => _showCreateEventSheet(context),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EventTimeFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter.label),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                              _triggerFilterFetch(filter);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocConsumer<EventsBloc, EventsState>(
                  listener: (context, state) {
                    if (state is EventsLoaded && state.rsvpError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.rsvpError!),
                          backgroundColor: context.churchColors.error,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is EventsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is EventsError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: context.churchColors.error),
                              const SizedBox(height: 12),
                              Text(
                                'Unable to load church calendar.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.churchColors.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.churchColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonal(
                                onPressed: () => _triggerFilterFetch(_selectedFilter),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (state is EventsLoaded) {
                      final events = state.events;

                      if (events.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy_rounded,
                                    size: 48, color: context.churchColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No ${_selectedFilter.label.toLowerCase()} scheduled.',
                                  style: TextStyle(
                                      fontSize: 16, color: context.churchColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventCard(context, event);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateEventSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final addressController = TextEditingController();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day + 1, 10, 0);
    final endDate = DateTime(now.year, now.month, now.day + 1, 12, 0);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.churchColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Post Church Event',
                    style: AppTheme.serif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.churchColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location Name (e.g. Main Sanctuary)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.churchColors.primary,
                      foregroundColor: context.churchColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isNotEmpty) {
                        context.read<EventsBloc>().add(
                              EventCreateRequested(
                                title: title,
                                description: descController.text.trim().isNotEmpty
                                    ? descController.text.trim()
                                    : null,
                                startsAt: startDate,
                                endsAt: endDate,
                                locationName: locationController.text.trim().isNotEmpty
                                    ? locationController.text.trim()
                                    : null,
                                address: addressController.text.trim().isNotEmpty
                                    ? addressController.text.trim()
                                    : null,
                              ),
                            );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Publish to Calendar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, ChurchEvent event) {
    final theme = Theme.of(context);
    final colors = context.churchColors;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(event.startsAt);
    final timeStr = DateFormat('h:mm a').format(event.startsAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.sanctuaryCard(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateTile(colors, event.startsAt),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'CHURCH-WIDE',
                            style: AppTheme.trackingBadge(color: colors.primary, fontSize: 9.5),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: AppTheme.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (event.location != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: colors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 24, color: colors.border.withValues(alpha: 0.5)),
          Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                '${event.attendingCount} attending',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (event.maybeCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(${event.maybeCount} maybe)',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              _buildRsvpButton(context, event),
            ],
          ),
        ],
      ),
    );
  }

  /// The day as a small calendar tile: month above a serif day number.
  Widget _buildDateTile(ChurchColors colors, DateTime date) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: AppTheme.trackingBadge(color: colors.primary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('d').format(date),
            style: AppTheme.serif(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButton(BuildContext context, ChurchEvent event) {
    final status = event.myRsvp;

    if (status == null) {
      return FilledButton.tonal(
        onPressed: () => _showRsvpDialog(context, event),
        child: const Text('RSVP'),
      );
    }

    final isAttending = status == RSVPStatus.attending;
    final isMaybe = status == RSVPStatus.maybe;

    return OutlinedButton.icon(
      icon: Icon(
        isAttending ? Icons.check_circle : (isMaybe ? Icons.help : Icons.cancel),
        size: 16,
        color: isAttending ? context.churchColors.success : (isMaybe ? context.churchColors.warning : context.churchColors.error),
      ),
      label: Text(status.label),
      onPressed: () => _showRsvpDialog(context, event),
    );
  }

  void _showRsvpDialog(BuildContext context, ChurchEvent event) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.churchColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'RSVP: ${event.title}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Let the pastoral team know if you will be attending this event:'),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.check_circle, color: context.churchColors.success),
                title: const Text('Attending'),
                selected: event.myRsvp == RSVPStatus.attending,
                onTap: () {
                  context.read<EventsBloc>().add(
                        EventRsvpSubmitted(
                           eventId: event.id,
                          status: RSVPStatus.attending,
                        ),
                      );
                  Navigator.pop(bottomSheetContext);
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: context.churchColors.warning),
                title: const Text('Maybe'),
                selected: event.myRsvp == RSVPStatus.maybe,
                onTap: () {
                  context.read<EventsBloc>().add(
                        EventRsvpSubmitted(
                          eventId: event.id,
                          status: RSVPStatus.maybe,
                        ),
                      );
                  Navigator.pop(bottomSheetContext);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: context.churchColors.error),
                title: const Text('Declined'),
                selected: event.myRsvp == RSVPStatus.declined,
                onTap: () {
                  context.read<EventsBloc>().add(
                        EventRsvpSubmitted(
                          eventId: event.id,
                          status: RSVPStatus.declined,
                        ),
                      );
                  Navigator.pop(bottomSheetContext);
                },
              ),
              if (event.myRsvp != null) ...[
                const Divider(),
                TextButton(
                  onPressed: () {
                    context.read<EventsBloc>().add(
                          EventRsvpWithdrawn(eventId: event.id),
                        );
                    Navigator.pop(bottomSheetContext);
                  },
                  child: Text('Withdraw My RSVP', style: TextStyle(color: context.churchColors.textMuted)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
