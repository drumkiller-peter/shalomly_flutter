import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/auth/presentation/widgets/user_avatar_button.dart';
import 'package:shalomly_app/src/features/prayer/domain/prayer_request.dart';
import 'package:shalomly_app/src/features/prayer/presentation/bloc/prayer_bloc.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final name = authState is Authenticated
                ? authState.user.fullName
                : 'Church Family';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$timeGreeting,',
                  style: AppTheme.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.churchColors.textMuted,
                  ),
                ),
                Text(
                  name,
                  style: AppTheme.serif(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: context.churchColors.text,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Prayer Chain',
            onPressed: () => context
                .read<PrayerBloc>()
                .add(const PrayerChainFetchRequested()),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: UserAvatarButton(compact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Section Banner Header (Inspired by Screenshot 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Testimonies & Prayer',
                        style: AppTheme.serif(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: context.churchColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Stories of faith and community intercession',
                        style: AppTheme.sans(
                          fontSize: 12,
                          color: context.churchColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.churchColors.secondary,
                    foregroundColor: context.churchColors.onSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
                  label: Text(
                    'Ask for Prayer',
                    style: AppTheme.sans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _openCreatePrayerSheet(context),
                ),
              ],
            ),
          ),

          // Custom Sanctuary Pill Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.churchColors.raised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.churchColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: context.churchColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: context.churchColors.onPrimary,
              unselectedLabelColor: context.churchColors.textMuted,
              labelStyle: AppTheme.sans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTheme.sans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Prayer Chain'),
                Tab(text: 'My Private Requests'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List content
          Expanded(
            child: BlocBuilder<PrayerBloc, PrayerState>(
              builder: (context, state) {
                if (state is PrayerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PrayerLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _PrayerListView(
                        prayers: state.publicPrayers,
                        isChain: true,
                        onAskForPrayer: () => _openCreatePrayerSheet(context),
                      ),
                      _PrayerListView(
                        prayers: state.privatePrayers,
                        isChain: false,
                        onAskForPrayer: () => _openCreatePrayerSheet(context),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openCreatePrayerSheet(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final pastorIdController = TextEditingController(text: '1');
    var isPrivate = false;
    var isAnonymous = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.churchColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.churchColors.border.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Submit Prayer Request',
                    style: AppTheme.serif(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.churchColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entrust your burdens to God and your church family.',
                    style: AppTheme.sans(
                      fontSize: 12.5,
                      color: context.churchColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title / Subject',
                      labelStyle: AppTheme.sans(fontSize: 13),
                      filled: true,
                      fillColor: context.churchColors.raised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.churchColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Prayer Request Details',
                      labelStyle: AppTheme.sans(fontSize: 13),
                      filled: true,
                      fillColor: context.churchColors.raised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.churchColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: context.churchColors.primary,
                    title: Text(
                      'Private Request (Pastor Only)',
                      style: AppTheme.sans(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Hidden from Prayer Chain; entrusted to Assigned Pastor',
                      style: AppTheme.sans(fontSize: 11.5, color: context.churchColors.textMuted),
                    ),
                    value: isPrivate,
                    onChanged: (val) {
                      setModalState(() {
                        isPrivate = val;
                        if (isPrivate) isAnonymous = false;
                      });
                    },
                  ),
                  if (isPrivate) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: pastorIdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Assigned Pastor ID',
                        hintText: 'e.g. 1',
                        labelStyle: AppTheme.sans(fontSize: 13),
                        filled: true,
                        fillColor: context.churchColors.raised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.churchColors.border),
                        ),
                      ),
                    ),
                  ],
                  if (!isPrivate)
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: context.churchColors.primary,
                      title: Text(
                        'Anonymous on Prayer Chain',
                        style: AppTheme.sans(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Your name stays hidden from other members',
                        style: AppTheme.sans(fontSize: 11.5, color: context.churchColors.textMuted),
                      ),
                      value: isAnonymous,
                      onChanged: (val) => setModalState(() => isAnonymous = val),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.churchColors.primary,
                      foregroundColor: context.churchColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      final pastorId = isPrivate ? int.tryParse(pastorIdController.text.trim()) : null;
                      if (title.isNotEmpty && content.isNotEmpty) {
                        context.read<PrayerBloc>().add(
                              PrayerCreateSubmitted(
                                title: title,
                                content: content,
                                isPrivate: isPrivate,
                                isAnonymous: isAnonymous,
                                assignedPastorId: pastorId,
                              ),
                            );
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(
                      'Submit Request',
                      style: AppTheme.sans(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrayerListView extends StatelessWidget {
  final List<PrayerRequest> prayers;
  final bool isChain;
  final VoidCallback onAskForPrayer;

  const _PrayerListView({
    required this.prayers,
    required this.isChain,
    required this.onAskForPrayer,
  });

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: AppTheme.sanctuaryCard(context.churchColors),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.churchColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  size: 30,
                  color: context.churchColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isChain
                    ? 'The Prayer Chain is currently clear.'
                    : 'No private prayer requests submitted.',
                style: AppTheme.serif(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.churchColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Share your heart with the church family or your pastors.',
                style: AppTheme.sans(
                  fontSize: 12.5,
                  color: context.churchColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.churchColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onAskForPrayer,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Submit a Prayer Request'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final author = prayer.isAnonymous
            ? 'Anonymous Member'
            : (prayer.authorName ?? 'Church Member');
        final initial = author.isNotEmpty ? author[0].toUpperCase() : 'M';
        final formattedDate = DateFormat('MMM d').format(prayer.createdAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.sanctuaryCard(context.churchColors),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Author & Status Row (Screenshot 3 styling)
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.churchColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: AppTheme.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.churchColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          style: AppTheme.sans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: context.churchColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formattedDate,
                          style: AppTheme.sans(
                            fontSize: 11,
                            color: context.churchColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (prayer.isPrivate)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.churchColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 11, color: context.churchColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                'CONFIDENTIAL',
                                style: AppTheme.trackingBadge(color: context.churchColors.warning),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          prayer.assignedPastorId != null
                              ? 'Assigned Pastor: #${prayer.assignedPastorId}'
                              : 'Unassigned',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: prayer.assignedPastorId != null
                                ? context.churchColors.textMuted
                                : context.churchColors.error,
                          ),
                        ),
                      ],
                    )
                  else if (prayer.status == PrayerStatus.answered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.churchColors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: context.churchColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'ANSWERED',
                            style: AppTheme.trackingBadge(color: context.churchColors.success),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: context.churchColors.secondary,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                prayer.title,
                style: AppTheme.serif(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.churchColors.text,
                ),
              ),
              const SizedBox(height: 6),

              // Content in warm italic serif
              Text(
                '“${prayer.content}”',
                style: AppTheme.serif(
                  fontSize: 14.5,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                  color: context.churchColors.text,
                ),
              ),

              if (isChain) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: context.churchColors.border.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${prayer.intercessionCount} intercessions',
                      style: AppTheme.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.churchColors.textMuted,
                      ),
                    ),
                    Material(
                      color: prayer.hasInterceded
                          ? context.churchColors.primary.withValues(alpha: 0.15)
                          : context.churchColors.raised,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<PrayerBloc>().add(
                                PrayerIntercessionToggled(
                                  prayerId: prayer.id,
                                  intercede: !prayer.hasInterceded,
                                ),
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: prayer.hasInterceded
                                  ? context.churchColors.primary.withValues(alpha: 0.5)
                                  : context.churchColors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                prayer.hasInterceded
                                    ? Icons.thumb_up_rounded
                                    : Icons.thumb_up_outlined,
                                size: 14,
                                color: prayer.hasInterceded
                                    ? context.churchColors.primary
                                    : context.churchColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                prayer.hasInterceded
                                    ? 'Interceding (${prayer.intercessionCount})'
                                    : 'Intercede (${prayer.intercessionCount})',
                                style: AppTheme.sans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: prayer.hasInterceded
                                      ? context.churchColors.primary
                                      : context.churchColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (prayer.pastoralNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.churchColors.raised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.churchColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: context.churchColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'PASTORAL CARE',
                            style: AppTheme.trackingBadge(color: context.churchColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...prayer.pastoralNotes.map(
                        (PastoralPrayerNote note) => Text(
                          '“${note.note ?? 'Prayed for you'}” — ${note.pastorName}',
                          style: AppTheme.serif(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: context.churchColors.text,
                          ),
                        ),
                      ),
                    ],
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
