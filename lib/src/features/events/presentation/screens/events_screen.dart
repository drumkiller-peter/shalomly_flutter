import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/widgets/member_session_scope.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_days.dart';
import 'package:shalomly_app/src/features/events/domain/event_time_filter.dart';
import 'package:shalomly_app/src/features/events/domain/share_targets.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/calendar_events_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/event_type_style.dart';
import 'package:shalomly_app/src/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:shalomly_app/src/features/groups/data/groups_repository.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventTimeFilter _selectedFilter = EventTimeFilter.upcoming;
  int? _sessionGeneration;

  /// The calendar above the list: the Events around the month it shows, the
  /// day it is on, the day the member tapped (none: the list below shows the
  /// chosen filter instead), and whether it is open to the whole month.
  late final CalendarEventsBloc _calendar;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _monthExpanded = false;
  int? _loadedMonth;

  @override
  void initState() {
    super.initState();
    _calendar = CalendarEventsBloc(
      repository: context.read<EventsRepository>(),
    );
  }

  @override
  void dispose() {
    _calendar.close();
    super.dispose();
  }

  /// Loads the month around the day the calendar is on, unless it already has
  /// it; [force] reads it again, after something changed.
  void _loadCalendar({bool force = false}) {
    final month = _focusedDay.year * 100 + _focusedDay.month;
    if (!force && month == _loadedMonth) return;
    _loadedMonth = month;
    _calendar.add(CalendarEventsLoadRequested(_focusedDay));
  }

  /// The arrows: a month at a time when open to the month, a week otherwise.
  void _moveCalendar(int step) {
    setState(() {
      _focusedDay = _monthExpanded
          ? DateTime(_focusedDay.year, _focusedDay.month + step, 1)
          : _focusedDay.add(Duration(days: 7 * step));
    });
    _loadCalendar();
  }

  void _selectDay(DateTime selected, DateTime focused) {
    setState(() {
      // Tapping the chosen day again goes back to the filtered list.
      _selectedDay = isSameDay(_selectedDay, selected) ? null : selected;
      _focusedDay = focused;
    });
    _loadCalendar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On first build, and again whenever someone else signs in: the new
    // member's RSVPs, under this screen's filter.
    final generation = MemberSessionScope.generationOf(context);
    if (generation != _sessionGeneration) {
      _sessionGeneration = generation;
      _triggerFilterFetch(_selectedFilter);
      _loadCalendar(force: true);
    }
  }

  void _triggerFilterFetch(EventTimeFilter filter) {
    final range = filter.rangeAt(DateTime.now());
    context.read<EventsBloc>().add(
      EventsFetchRequested(
        startsAfter: range.startsAfter,
        startsBefore: range.startsBefore,
        newestFirst: range.newestFirst,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final canPost =
            authState is Authenticated &&
            authState.user.role.canPostChurchEvents;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Church Calendar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _triggerFilterFetch(_selectedFilter);
                  _loadCalendar(force: true);
                },
              ),
            ],
          ),
          floatingActionButton: canPost
              ? FloatingActionButton.extended(
                  backgroundColor: context.churchColors.primary,
                  foregroundColor: context.churchColors.onPrimary,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(TranslationString.eventFormPostTitle.tr()),
                  onPressed: () => _postEvent(context),
                )
              : null,
          body: ListView(
            children: [
              _buildCalendar(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EventTimeFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter.label),
                          // With a day chosen no filter is, until one is tapped.
                          selected:
                              _selectedDay == null && _selectedFilter == filter,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                                _selectedDay = null;
                              });
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
              BlocConsumer<EventsBloc, EventsState>(
                listener: (context, state) {
                  if (state is EventsLoaded && state.postedCount != null) {
                    _showPostResult(context, state);
                    _loadCalendar(force: true);
                  }
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
                  // The chosen day's Events are shown below instead.
                  if (_selectedDay != null) return const SizedBox.shrink();
                  if (state is EventsLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is EventsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: context.churchColors.error,
                            ),
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
                              onPressed: () =>
                                  _triggerFilterFetch(_selectedFilter),
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
                      return _buildEmptyState(context);
                    }

                    final days = groupEventsByDay(
                      events,
                      mostRecentFirst: _selectedFilter == EventTimeFilter.past,
                    );
                    return ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final day in days) ...[
                          _buildDayHeader(context, day.day),
                          for (final event in day.events)
                            _buildEventCard(context, event),
                        ],
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_selectedDay != null)
                ..._buildDaySection(context, _selectedDay!),
            ],
          ),
        );
      },
    );
  }

  /// The week, or the whole month when opened up, with a dot on each day that
  /// has an Event. Tapping a day shows that day's Events below.
  Widget _buildCalendar(BuildContext context) {
    final colors = context.churchColors;
    return BlocBuilder<CalendarEventsBloc, CalendarEventsState>(
      bloc: _calendar,
      builder: (context, state) {
        final markerStyle = TextStyle(fontSize: 16, color: colors.text);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: AppTheme.sanctuaryCard(colors),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: TranslationString.calendarPrevious.tr(),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _moveCalendar(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_focusedDay),
                      textAlign: TextAlign.center,
                      style: AppTheme.serif(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: TranslationString.calendarNext.tr(),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => _moveCalendar(1),
                  ),
                ],
              ),
              TableCalendar<ChurchEvent>(
                firstDay: DateTime.utc(2000),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _monthExpanded
                    ? CalendarFormat.month
                    : CalendarFormat.week,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                headerVisible: false,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                rowHeight: 48,
                daysOfWeekHeight: 28,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => eventsOnDay(state.events, day),
                onDaySelected: _selectDay,
                onPageChanged: (focused) {
                  _focusedDay = focused;
                  setState(() {});
                  _loadCalendar();
                },
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: markerStyle,
                  weekendTextStyle: markerStyle,
                  outsideTextStyle: TextStyle(
                    fontSize: 16,
                    color: colors.textMuted,
                  ),
                  todayTextStyle: markerStyle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 1.5),
                  ),
                  selectedTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimary,
                  ),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                  markerDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.warning,
                  ),
                  markersMaxCount: 3,
                  markerSize: 6,
                  markersAlignment: Alignment.bottomCenter,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: Icon(
                  _monthExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  (_monthExpanded
                          ? TranslationString.calendarShowWeek
                          : TranslationString.calendarShowMonth)
                      .tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: () =>
                    setState(() => _monthExpanded = !_monthExpanded),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The Events of the day the member tapped, with a way back to the list.
  List<Widget> _buildDaySection(BuildContext context, DateTime day) {
    final colors = context.churchColors;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM').format(day),
                style: AppTheme.serif(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => setState(() => _selectedDay = null),
              child: Text(
                TranslationString.calendarShowAll.tr(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      BlocBuilder<CalendarEventsBloc, CalendarEventsState>(
        bloc: _calendar,
        builder: (context, state) {
          if (state.status == CalendarEventsStatus.error) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    TranslationString.calendarLoadFailed.tr(),
                    style: TextStyle(fontSize: 16, color: colors.error),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () => _loadCalendar(force: true),
                    child: Text(TranslationString.calendarRetry.tr()),
                  ),
                ],
              ),
            );
          }
          if (state.status != CalendarEventsStatus.loaded &&
              state.events.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final events = eventsOnDay(state.events, day);
          if (events.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                TranslationString.calendarDayEmpty.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: colors.textMuted),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                for (final event in events) _buildDayTile(context, event),
              ],
            ),
          );
        },
      ),
    ];
  }

  /// One Event of the chosen day: its type, title, time and place. Opens it.
  Widget _buildDayTile(BuildContext context, ChurchEvent event) {
    final colors = context.churchColors;
    final timeFormat = DateFormat('h:mm a');
    final time = event.endsAt == null
        ? timeFormat.format(event.startsAt)
        : '${timeFormat.format(event.startsAt)} – ${timeFormat.format(event.endsAt!)}';
    final place = event.location;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Ink(
        decoration: AppTheme.sanctuaryCard(colors),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openEvent(context, event),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
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
                          style: AppTheme.serif(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                        Text(
                          place == null || place.isEmpty
                              ? time
                              : '$time · $place',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textMuted,
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
        ),
      ),
    );
  }

  /// What this screen lists is scheduled church activities, so an empty list
  /// says so, rather than hinting at notices or documents.
  Widget _buildEmptyState(BuildContext context) {
    final colors = context.churchColors;
    final (title, hint) = switch (_selectedFilter) {
      EventTimeFilter.upcoming => (
        TranslationString.eventsEmptyUpcomingTitle,
        TranslationString.eventsEmptyUpcomingHint,
      ),
      EventTimeFilter.thisWeek => (
        TranslationString.eventsEmptyThisWeekTitle,
        null,
      ),
      EventTimeFilter.past => (TranslationString.eventsEmptyPastTitle, null),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              title.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, DateTime day) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        DateFormat('EEEE, d MMMM').format(day),
        style: AppTheme.serif(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: context.churchColors.text,
        ),
      ),
    );
  }

  /// Opens one Event, and shows the calendar again afterwards, since the
  /// member may have answered, edited, cancelled or deleted it there.
  Future<void> _openEvent(BuildContext context, ChurchEvent event) async {
    await context.push(AppRoutes.eventDetail(event.id));
    if (mounted) {
      _triggerFilterFetch(_selectedFilter);
      _loadCalendar(force: true);
    }
  }

  Future<void> _postEvent(BuildContext context) async {
    final bloc = context.read<EventsBloc>();
    final groupsRepository = context.read<GroupsRepository>();
    final auth = context.read<AuthBloc>().state;
    final role = auth is Authenticated ? auth.user.role : null;
    List<Group> groups = const [];
    try {
      groups = shareableGroups(await groupsRepository.fetchGroups(), role);
    } catch (_) {
      // No Groups to offer is better than no way to post.
    }
    if (!context.mounted) return;
    final result = await showEventFormSheet(context, shareableGroups: groups);
    if (result != null) {
      bloc.add(EventCreateRequested(result.draft, shareWith: result.shareWith));
    }
  }

  /// What posting did, in words: how many went through, and what didn't.
  void _showPostResult(BuildContext context, EventsLoaded state) {
    final posted = state.postedCount ?? 0;
    final failed = state.postFailedCount ?? 0;
    final colors = context.churchColors;
    final String message;
    if (failed == 0) {
      message = posted == 1
          ? TranslationString.eventPostedOne.tr()
          : TranslationString.eventPostedMany.tr(args: ['$posted']);
    } else if (posted == 0) {
      message = TranslationString.eventPostFailedAll.tr();
    } else {
      message = TranslationString.eventPostFailedSome.tr(
        args: ['$posted', '$failed'],
      );
    }
    final notShared = state.shareFailedGroups;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notShared.isEmpty
              ? message
              : '$message\n${TranslationString.eventShareFailed.tr(args: [notShared.join(', ')])}',
        ),
        backgroundColor: failed == 0 && notShared.isEmpty ? null : colors.error,
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, ChurchEvent event) {
    final theme = Theme.of(context);
    final colors = context.churchColors;
    final timeFormat = DateFormat('h:mm a');
    final timeStr = event.endsAt == null
        ? timeFormat.format(event.startsAt)
        : '${timeFormat.format(event.startsAt)} – ${timeFormat.format(event.endsAt!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Ink(
        decoration: AppTheme.sanctuaryCard(colors),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openEvent(context, event),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      event.type.icon,
                                      size: 16,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      event.type.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                timeStr,
                                style: theme.textTheme.bodyMedium?.copyWith(
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
                        ],
                      ),
                    ),
                  ],
                ),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
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
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colors.secondary,
                      ),
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
                Divider(
                  height: 24,
                  color: colors.border.withValues(alpha: 0.5),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${event.attendingCount} attending',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (event.maybeCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${event.maybeCount} maybe)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Spacer(),
                    _buildRsvpButton(context, event),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        isAttending
            ? Icons.check_circle
            : (isMaybe ? Icons.help : Icons.cancel),
        size: 16,
        color: isAttending
            ? context.churchColors.success
            : (isMaybe
                  ? context.churchColors.warning
                  : context.churchColors.error),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Let the pastoral team know if you will be attending this event:',
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: context.churchColors.success,
                ),
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
                leading: Icon(
                  Icons.help_outline,
                  color: context.churchColors.warning,
                ),
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
                leading: Icon(
                  Icons.cancel_outlined,
                  color: context.churchColors.error,
                ),
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
                  child: Text(
                    'Withdraw My RSVP',
                    style: TextStyle(color: context.churchColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
