import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/core/utils/extensions/date_time_extension.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/widgets/user_avatar_button.dart';
import 'package:shalomly_app/src/features/devotional/domain/daily_quote.dart';
import 'package:shalomly_app/src/features/devotional/presentation/bloc/devotional_bloc.dart';
import 'package:shalomly_app/src/features/sermons/domain/sermon.dart';
import 'package:shalomly_app/src/features/sermons/presentation/bloc/sermons_bloc.dart';
import 'package:shalomly_app/src/features/service_times/domain/service_time.dart';
import 'package:shalomly_app/src/features/service_times/presentation/bloc/service_times_bloc.dart';
import 'package:shalomly_app/src/shared/app_icon.dart';
import 'package:shalomly_app/src/shared/app_rounded_card.dart';
import 'package:shalomly_app/src/shared/app_text.dart';
import 'package:shalomly_app/src/shared/k_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();
    final todayFormatted = _selectedDate.toDoWMDFormat();
    return Scaffold(
      appBar: CustomAppBar(
        titleSpacing: 16,
        titleWidget: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.churchColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                Icons.church_rounded,
                color: context.churchColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appConfig.churchName,
                    style: AppTheme.serif(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: context.churchColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    todayFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.churchColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsWidget: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Devotional',
            onPressed: () => context.read<DevotionalBloc>().add(
              DevotionalFetchRequested(forceRefresh: true),
            ),
          ),
          const UserAvatarButton(compact: true),
          const Gap(16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DevotionalBloc>().add(
            DevotionalFetchRequested(forceRefresh: true),
          );
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // 1. Warm Greeting & Worship Status
            _buildSanctuaryHero(context),
            const SizedBox(height: 18),

            // 2. Slim Action Pills (Replacing 8-box grid)
            _buildQuickActionPills(context),
            const SizedBox(height: 18),

            // 3. Weekday Calendar Strip
            _buildWeekdayStrip(context),
            const SizedBox(height: 18),

            // 4. Daily Scripture / Verse of the Day Sanctuary Card
            _buildDevotionalSection(context),
            const SizedBox(height: 22),

            // 5. Fellowship Highlights Pulse
            _buildFellowshipPulse(context),
            const SizedBox(height: 20),

            // 6. Featured Sermon Media Spotlight
            _buildFeaturedSermonSpotlight(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSanctuaryHero(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAuthenticated = state is Authenticated;
        final hour = DateTime.now().hour;
        final timeGreeting = hour < 12
            ? 'Good morning'
            : (hour < 17 ? 'Good afternoon' : 'Good evening');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome / Greeting Row (No Truncation)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 6.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated
                              ? '$timeGreeting, ${state.user.fullName.split(' ').first}'
                              : 'Welcome to Fellowship',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: context.churchColors.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAuthenticated
                              ? 'Grace and peace to you today'
                              : 'May God’s peace and grace fill your day',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.churchColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAuthenticated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.churchColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: context.churchColors.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        state.user.role.value.toUpperCase(),
                        style: TextStyle(
                          color: context.churchColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Worship spotlight: the one filled moment on the page
            _buildWorshipSpotlight(context),
          ],
        );
      },
    );
  }

  /// The church's next Service Time, with Order of Service. A church with
  /// none shows the card without a day or time rather than an invented one.
  Widget _buildWorshipSpotlight(BuildContext context) {
    return BlocBuilder<ServiceTimesBloc, ServiceTimesState>(
      builder: (context, state) {
        final next = ServiceTime.next(state.serviceTimes, DateTime.now());
        final others = state.serviceTimes.where((s) => s != next);
        final details = [
          if (next?.location != null) next!.location!,
          ...others.map((s) => '${s.name} · ${s.dayName} ${s.formattedTime}'),
        ].join('\n');
        final subtitle = details.isEmpty
            ? 'Worship, communion, and preaching of the Word'
            : details;
        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient(context.churchColors),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: context.churchColors.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.churchColors.onPrimary.withValues(
                        alpha: 0.16,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      size: 18,
                      color: context.churchColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      next == null
                          ? 'WEEKLY WORSHIP'
                          : '${next.dayName.toUpperCase()} • ${next.formattedTime}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.churchColors.onPrimary.withValues(
                          alpha: 0.85,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.churchColors.onPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      TranslationString.thisWeek.tr(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: context.churchColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                next?.name ?? 'Worship With Us',
                style: AppTheme.serif(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                  color: context.churchColors.onPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: context.churchColors.onPrimary.withValues(
                    alpha: 0.82,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.churchColors.onPrimary,
                        foregroundColor: context.churchColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.auto_stories_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Order of Service',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => context.push(AppRoutes.bulletins),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekdayStrip(BuildContext context) {
    final now = DateTime.now();
    // Week starts on Sunday
    final sunday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday % 7));
    final weekDays = List.generate(7, (i) => sunday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: context.churchColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.churchColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: context.churchColors.text.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((date) {
          final isSelected =
              _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final isToday =
              now.year == date.year &&
              now.month == date.month &&
              now.day == date.day;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected
                    ? context.churchColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: !isSelected && isToday
                          ? Border.all(
                              color: context.churchColors.primary.withValues(
                                alpha: 0.5,
                              ),
                              width: 1.2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: AppTheme.sans(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            letterSpacing: 0.6,
                            color: isSelected
                                ? context.churchColors.onPrimary.withValues(
                                    alpha: 0.88,
                                  )
                                : context.churchColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: AppTheme.serif(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: isSelected
                                ? context.churchColors.onPrimary
                                : (isToday
                                      ? context.churchColors.primary
                                      : context.churchColors.text),
                          ),
                        ),
                        if (isToday && !isSelected) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.churchColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDevotionalSection(BuildContext context) {
    return BlocBuilder<DevotionalBloc, DevotionalState>(
      builder: (context, state) {
        if (state.status == DevotionalStatus.loading) {
          return Container(
            height: 160,
            decoration: BoxDecoration(
              color: context.churchColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.churchColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == DevotionalStatus.error) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.churchColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.churchColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: context.churchColors.error,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorFetchingQuotes ?? '',
                  style: TextStyle(
                    color: context.churchColors.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => context.read<DevotionalBloc>().add(
                    DevotionalFetchRequested(forceRefresh: true),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final quote =
            (state.status == DevotionalStatus.loaded &&
                state.quotes!.isNotEmpty)
            ? state.quotes!.first
            : DailyQuote.fallback;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Today's Scripture
            _buildSanctuaryScriptureCard(context, quote),
            const SizedBox(height: 14),

            // Card 2: Reflection
            _buildSanctuaryReflectionCard(context, quote),
            const SizedBox(height: 14),

            // Card 3: Prayer for Today
            _buildSanctuaryPrayerCard(context),
          ],
        );
      },
    );
  }

  Widget _buildSanctuaryScriptureCard(BuildContext context, DailyQuote quote) {
    return AppRoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.churchColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      Icons.auto_stories_rounded,
                      size: 13,
                      color: context.churchColors.primary,
                    ),
                    const SizedBox(width: 5),
                    AppText(
                      TranslationString.todaysScripture.tr(),
                      style: AppTheme.trackingBadge(
                        color: context.churchColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (quote.date != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.churchColors.raised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: context.churchColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    quote.date!,
                    style: AppTheme.sans(
                      fontSize: 11,
                      color: context.churchColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (quote.authorName != null) ...[
            Text(
              quote.authorName!,
              style: AppTheme.serif(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: context.churchColors.text,
              ),
            ),
            const SizedBox(height: 10),
          ],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: context.churchColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '“${quote.content}”',
                    style: AppTheme.serif(
                      fontSize: 18,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: context.churchColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: context.churchColors.border.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: context.churchColors.textMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(
                  TranslationString.copyVerse.tr(),
                  style: AppTheme.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '${quote.content}\n— ${quote.authorName ?? "Scripture"}',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        TranslationString.scriptureCopiedToClipboard.tr(),
                      ),
                      backgroundColor: context.churchColors.surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.churchColors.border),
                      ),
                    ),
                  );
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.churchColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 16,
                    ),
                    label: Text(
                      'Pray',
                      style: AppTheme.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.prayer),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.churchColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.library_music_rounded, size: 16),
                    label: Text(
                      'Hymnal',
                      style: AppTheme.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.hymns),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSanctuaryReflectionCard(BuildContext context, DailyQuote quote) {
    return Container(
      decoration: BoxDecoration(
        color: context.churchColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.churchColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: context.churchColors.text.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.churchColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 13,
                      color: context.churchColors.secondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'REFLECTION',
                      style: AppTheme.trackingBadge(
                        color: context.churchColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'PASTORAL INSIGHT',
                style: AppTheme.sans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.churchColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The Peace That Transcends Understanding',
            style: AppTheme.serif(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.churchColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In moments of uncertainty, God invites us into honest communion. Peace is not the absence of trials, but the abiding presence of Christ. As we bring our concerns before the Father with thanksgiving, His grace guards our hearts and renews our spirits for the journey.',
            style: AppTheme.sans(
              fontSize: 13.5,
              height: 1.6,
              color: context.churchColors.text.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctuaryPrayerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.churchColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.churchColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: context.churchColors.text.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.churchColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      size: 13,
                      color: context.churchColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'PRAYER FOR TODAY',
                      style: AppTheme.trackingBadge(
                        color: context.churchColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'GUIDED PRAYER',
                style: AppTheme.sans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.churchColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '“Heavenly Father, quiet my racing thoughts today. When worries press in, remind me of Your steadfast love and sovereign care. Guard my heart with the peace that only You can give, and teach me to walk faithfully in the footsteps of Christ. Amen.”',
            style: AppTheme.serif(
              fontSize: 15,
              height: 1.65,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: context.churchColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: context.churchColors.border.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Bring your petitions to the community',
                  style: AppTheme.sans(
                    fontSize: 11.5,
                    color: context.churchColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: context.churchColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(
                  'Prayer Chain',
                  style: AppTheme.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => context.push(AppRoutes.prayer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPills(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildActionPill(
            context: context,
            icon: Icons.auto_stories_rounded,
            label: 'Bulletins',
            color: context.churchColors.primary,
            route: AppRoutes.bulletins,
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context: context,
            icon: Icons.campaign_rounded,
            label: 'Announcements',
            color: context.churchColors.warning,
            route: AppRoutes.announcements,
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context: context,
            icon: Icons.smart_display_rounded,
            label: 'Watch Sermons',
            color: context.churchColors.secondary,
            route: AppRoutes.sermons,
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context: context,
            icon: Icons.groups_rounded,
            label: 'Small Groups',
            color: context.churchColors.success,
            route: AppRoutes.groups,
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            context: context,
            icon: Icons.admin_panel_settings_rounded,
            label: 'Church Workspace',
            color: context.churchColors.info,
            route: AppRoutes.admin,
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return Material(
      color: context.churchColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.churchColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFellowshipPulse(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.churchColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.churchColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: context.churchColors.text.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.churchColors.success.withValues(
                        alpha: 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hub_rounded,
                      size: 18,
                      color: context.churchColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'FELLOWSHIP HIGHLIGHTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: context.churchColors.success,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.churchColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: context.churchColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Community Intercession & Gatherings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.churchColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect with church life, share prayer requests, and join fellowship meetings',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: context.churchColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCommunityHighlightCard(
                  context: context,
                  badge: 'PRAYER CHAIN',
                  badgeColor: context.churchColors.error,
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Intercession',
                  subtitle:
                      'Stand together in faith for church needs & healing',
                  actionLabel: 'Pray Together',
                  route: AppRoutes.prayer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCommunityHighlightCard(
                  context: context,
                  badge: 'CALENDAR',
                  badgeColor: context.churchColors.info,
                  icon: Icons.calendar_month_rounded,
                  title: 'Gatherings',
                  subtitle: 'Fellowship meals, prayer vigils, & Bible study',
                  actionLabel: 'View Schedule',
                  route: AppRoutes.events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHighlightCard({
    required BuildContext context,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required String route,
  }) {
    return Material(
      color: context.churchColors.raised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.churchColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: badgeColor, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: context.churchColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: context.churchColors.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: badgeColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSermonSpotlight(BuildContext context) {
    return BlocBuilder<SermonsBloc, SermonsState>(
      builder: (context, state) {
        final Sermon sermon;
        if (state is SermonsLoaded && state.allSermons.isNotEmpty) {
          sermon = state.allSermons.first;
        } else {
          sermon = Sermon.fallback;
        }

        final preachedDateStr = DateFormat('MMMM d, yyyy')
            .format(sermon.preachedOn);

        return Container(
          decoration: BoxDecoration(
            color: context.churchColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.churchColors.border.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: context.churchColors.text.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.churchColors.secondary.withValues(
                            alpha: 0.14,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 18,
                          color: context.churchColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'FEATURED SERMON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: context.churchColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      foregroundColor: context.churchColors.secondary,
                    ),
                    icon: const Icon(Icons.video_library_rounded, size: 14),
                    label: const Text(
                      'All Sermons',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.sermons),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // High-Aspect Video Preview with Play Overlay
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(sermon.youtubeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: sermon.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: context.churchColors.raised,
                            child: Center(
                              child: Icon(
                                Icons.movie_filter_rounded,
                                size: 36,
                                color: context.churchColors.textMuted
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: context.churchColors.raised,
                            child: Center(
                              child: Icon(
                                Icons.video_library_rounded,
                                size: 48,
                                color: context.churchColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Subtle vignette for contrast
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                context.churchColors.surface.withValues(
                                  alpha: 0.0,
                                ),
                                context.churchColors.raised.withValues(
                                  alpha: 0.45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Centered Play Button
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.churchColors.surface.withValues(
                            alpha: 0.92,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.churchColors.text.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: context.churchColors.secondary,
                          size: 34,
                        ),
                      ),
                      // Bottom right YouTube badge
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.churchColors.surface.withValues(
                              alpha: 0.92,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: context.churchColors.border.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ondemand_video_rounded,
                                color: context.churchColors.error,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'YouTube',
                                style: TextStyle(
                                  color: context.churchColors.text,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                sermon.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.churchColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Preacher Attribution & Date Row
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: context.churchColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      sermon.preacher,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.churchColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: context.churchColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: context.churchColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    preachedDateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.churchColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (sermon.description != null &&
                  sermon.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sermon.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.churchColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Direct Watch Action & Details
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.churchColors.secondary,
                        foregroundColor: context.churchColors.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text(
                        'Watch Sermon',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(sermon.youtubeUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                      side: BorderSide(color: context.churchColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.video_library_outlined,
                      size: 16,
                      color: context.churchColors.secondary,
                    ),
                    label: Text(
                      'Archive',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.churchColors.text,
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.sermons),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
