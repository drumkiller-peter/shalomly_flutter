import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/sermons/domain/sermon.dart';
import 'package:shalomly_app/src/features/sermons/presentation/bloc/sermons_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SermonsScreen extends StatelessWidget {
  const SermonsScreen({super.key});

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
              'Sermons & Media',
              style: AppTheme.serif(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.churchColors.text,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Preaching and worship archives',
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
            tooltip: 'Refresh Sermons',
            onPressed: () {
              context.read<SermonsBloc>().add(const RefreshSermons());
            },
          ),
        ],
      ),
      body: BlocBuilder<SermonsBloc, SermonsState>(
        builder: (context, state) {
          if (state is SermonsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SermonError) {
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
                      'Failed to load sermons: ${state.message}',
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
                        context.read<SermonsBloc>().add(const LoadSermons());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SermonsLoaded) {
            return Column(
              children: [
                // Sanctuary Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.churchColors.raised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.churchColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                    child: TextField(
                      onChanged: (query) {
                        context.read<SermonsBloc>().add(SearchSermons(query));
                      },
                      decoration: InputDecoration(
                        hintText: 'Search sermons or scriptures...',
                        hintStyle: AppTheme.sans(
                          fontSize: 13,
                          color: context.churchColors.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.churchColors.textMuted,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // Preacher filter chips
                if (state.preachers.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              'All Preachers',
                              style: AppTheme.sans(
                                fontSize: 12,
                                fontWeight: state.selectedPreacher == null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: state.selectedPreacher == null
                                    ? context.churchColors.onPrimary
                                    : context.churchColors.text,
                              ),
                            ),
                            selected: state.selectedPreacher == null,
                            selectedColor: context.churchColors.primary,
                            backgroundColor: context.churchColors.raised,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: state.selectedPreacher == null
                                    ? context.churchColors.primary.withValues(alpha: 0)
                                    : context.churchColors.border,
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (_) {
                              context
                                  .read<SermonsBloc>()
                                  .add(const FilterSermonsByPreacher(null));
                            },
                          ),
                        ),
                        ...state.preachers.map(
                          (preacher) {
                            final isSelected = state.selectedPreacher == preacher;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  preacher,
                                  style: AppTheme.sans(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? context.churchColors.onPrimary
                                        : context.churchColors.text,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: context.churchColors.primary,
                                backgroundColor: context.churchColors.raised,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  side: BorderSide(
                                    color: isSelected
                                        ? context.churchColors.primary.withValues(alpha: 0)
                                        : context.churchColors.border,
                                  ),
                                ),
                                showCheckmark: false,
                                onSelected: (_) {
                                  context.read<SermonsBloc>().add(
                                        FilterSermonsByPreacher(
                                          isSelected ? null : preacher,
                                        ),
                                      );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // Sermons List
                Expanded(
                  child: state.filteredSermons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 48,
                                color: context.churchColors.textMuted.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No sermons found matching criteria.',
                                style: AppTheme.serif(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.churchColors.text,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context
                                .read<SermonsBloc>()
                                .add(const RefreshSermons());
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: state.filteredSermons.length,
                            itemBuilder: (context, index) {
                              final sermon = state.filteredSermons[index];
                              return _buildSermonCard(context, sermon);
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSermonCard(BuildContext context, Sermon sermon) {
    final dateStr = DateFormat('MMMM d, yyyy').format(sermon.preachedOn);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.sanctuaryCard(context.churchColors, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSermonDetails(context, sermon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail with Play Overlay
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: sermon.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: context.churchColors.raised,
                      child: const Center(child: CircularProgressIndicator()),
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.churchColors.surface.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.churchColors.text.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: context.churchColors.secondary,
                    size: 32,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.churchColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: context.churchColors.border.withValues(alpha: 0.6),
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
                          style: AppTheme.sans(
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

            // Content details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sermon.title,
                    style: AppTheme.serif(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: context.churchColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
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
                          style: AppTheme.sans(
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
                        size: 12,
                        color: context.churchColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: AppTheme.sans(
                          fontSize: 11.5,
                          color: context.churchColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (sermon.description != null && sermon.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      sermon.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(
                        fontSize: 12.5,
                        height: 1.45,
                        color: context.churchColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.churchColors.secondary,
                            foregroundColor: context.churchColors.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(
                            'Watch Sermon',
                            style: AppTheme.sans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse(sermon.youtubeUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.churchColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: context.churchColors.textMuted,
                        ),
                        label: Text(
                          'Notes',
                          style: AppTheme.sans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.churchColors.text,
                          ),
                        ),
                        onPressed: () => _showSermonDetails(context, sermon),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSermonDetails(BuildContext context, Sermon sermon) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.churchColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(sermon.preachedOn);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                sermon.title,
                style: AppTheme.serif(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.churchColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: context.churchColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sermon.preacher,
                    style: AppTheme.sans(
                      color: context.churchColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Preached on $dateStr',
                style: AppTheme.sans(
                  fontSize: 12,
                  color: context.churchColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: context.churchColors.border.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              if (sermon.description != null && sermon.description!.isNotEmpty) ...[
                Text(
                  'Sermon Notes & Scripture',
                  style: AppTheme.serif(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.churchColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sermon.description!,
                  style: AppTheme.sans(
                    fontSize: 13,
                    height: 1.5,
                    color: context.churchColors.text.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text(
                    'Watch on YouTube',
                    style: AppTheme.sans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.churchColors.secondary,
                    foregroundColor: context.churchColors.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(sermon.youtubeUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
