import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/announcements/domain/announcement.dart';
import 'package:shalomly_app/src/features/announcements/presentation/bloc/announcements_bloc.dart';

/// The church's current Announcements, newest first, with urgent ones at the top.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Announcements',
              style: AppTheme.serif(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.churchColors.text,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Notices for the whole church',
              style: AppTheme.sans(
                fontSize: 11,
                color: context.churchColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Announcements',
            onPressed: () {
              context.read<AnnouncementsBloc>().add(const LoadAnnouncements());
            },
          ),
        ],
      ),
      body: BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
        builder: (context, state) {
          if (state is AnnouncementsLoading || state is AnnouncementsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnnouncementsError) {
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
                      "Couldn't load announcements. Check your connection and try again.",
                      textAlign: TextAlign.center,
                      style: AppTheme.sans(
                        color: context.churchColors.error,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.churchColors.primary,
                        foregroundColor: context.churchColors.onPrimary,
                      ),
                      onPressed: () {
                        context.read<AnnouncementsBloc>().add(
                          const LoadAnnouncements(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final announcements = (state as AnnouncementsLoaded).announcements;
          final urgent = announcements.where((a) => a.isUrgent);
          final regular = announcements.where((a) => !a.isUrgent);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AnnouncementsBloc>().add(const LoadAnnouncements());
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (announcements.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.sanctuaryCard(
                      context.churchColors,
                      radius: 20,
                    ),
                    child: Center(
                      child: Text(
                        'No announcements right now.',
                        style: AppTheme.sans(
                          color: context.churchColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ...urgent.map((a) => _buildUrgentCard(context, a)),
                ...regular.map((a) => _buildAnnouncementCard(context, a)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUrgentCard(BuildContext context, Announcement announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.churchColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.churchColors.error.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.campaign_rounded,
            color: context.churchColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.churchColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'URGENT',
                        style: TextStyle(
                          color: context.churchColors.onError,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: AppTheme.serif(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.churchColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  announcement.body,
                  style: AppTheme.sans(
                    fontSize: 13,
                    height: 1.45,
                    color: context.churchColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Announcement announcement,
  ) {
    final dateStr = DateFormat('MMM d, yyyy').format(announcement.publishAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.sanctuaryCard(context.churchColors, radius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: AppTheme.serif(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: context.churchColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.churchColors.raised,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: AppTheme.sans(
                    fontSize: 11,
                    color: context.churchColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.body,
            style: AppTheme.sans(
              fontSize: 13,
              color: context.churchColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
