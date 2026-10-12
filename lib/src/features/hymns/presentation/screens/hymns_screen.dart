import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/core/localization/bilingual_text.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/hymns/domain/hymn.dart';
import 'package:shalomly_app/src/features/hymns/presentation/bloc/hymns_bloc.dart';

class HymnsScreen extends StatefulWidget {
  const HymnsScreen({super.key});

  @override
  State<HymnsScreen> createState() => _HymnsScreenState();
}

class _HymnsScreenState extends State<HymnsScreen> {
  String _searchQuery = '';
  bool _filterBookmarkedOnly = false;

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
              'Hymnal & Psalms',
              style: AppTheme.serif(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.churchColors.text,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Bilingual worship songbook',
              style: AppTheme.sans(
                fontSize: 11,
                color: context.churchColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _filterBookmarkedOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _filterBookmarkedOnly ? context.churchColors.warning : null,
              size: 22,
            ),
            tooltip: _filterBookmarkedOnly ? 'Show all hymns' : 'Show bookmarked only',
            onPressed: () {
              setState(() {
                _filterBookmarkedOnly = !_filterBookmarkedOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Hymnal',
            onPressed: () => context
                .read<HymnsBloc>()
                .add(const HymnsFetchRequested(forceRefresh: true)),
          ),
        ],
      ),
      body: Column(
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
                decoration: InputDecoration(
                  hintText: 'Search hymn number, title or lyrics...',
                  hintStyle: AppTheme.sans(
                    fontSize: 13,
                    color: context.churchColors.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.churchColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<HymnsBloc, HymnsState>(
              builder: (context, state) {
                if (state is HymnsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is HymnsLoaded) {
                  var filtered = state.hymns;
                  if (_filterBookmarkedOnly) {
                    filtered = filtered.where((h) => h.isBookmarked).toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((h) {
                      return h.hymnNumber.toString().contains(_searchQuery) ||
                          h.titleEn.toLowerCase().contains(_searchQuery) ||
                          h.titleNe.toLowerCase().contains(_searchQuery) ||
                          h.lyricsEn.toLowerCase().contains(_searchQuery) ||
                          h.lyricsNe.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_music_outlined,
                            size: 48,
                            color: context.churchColors.textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterBookmarkedOnly
                                ? 'No bookmarked hymns.'
                                : 'No hymns found matching query.',
                            style: AppTheme.serif(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.churchColors.text,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final hymn = filtered[index];
                      final localizedTitle = BilingualText(
                        en: hymn.titleEn,
                        ne: hymn.titleNe,
                      ).of(context);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: AppTheme.sanctuaryCard(context.churchColors, radius: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: context.churchColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${hymn.hymnNumber}',
                              style: AppTheme.serif(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: context.churchColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            localizedTitle.isNotEmpty ? localizedTitle : hymn.titleEn,
                            style: AppTheme.serif(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: context.churchColors.text,
                            ),
                          ),
                          subtitle: Text(
                            hymn.titleNe.isNotEmpty && hymn.titleNe != localizedTitle
                                ? hymn.titleNe
                                : hymn.titleEn,
                            style: AppTheme.sans(
                              fontSize: 12,
                              color: context.churchColors.textMuted,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              hymn.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: hymn.isBookmarked ? context.churchColors.warning : context.churchColors.textMuted,
                              size: 22,
                            ),
                            onPressed: () {
                              context.read<HymnsBloc>().add(
                                    HymnBookmarkToggled(
                                      hymnId: hymn.id,
                                      isBookmarked: !hymn.isBookmarked,
                                    ),
                                  );
                            },
                          ),
                          onTap: () => _openHymnDetails(context, hymn),
                        ),
                      );
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
  }

  void _openHymnDetails(BuildContext context, Hymn hymn) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.churchColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _HymnDetailSheet(hymn: hymn),
    );
  }
}

class _HymnDetailSheet extends StatefulWidget {
  final Hymn hymn;
  const _HymnDetailSheet({required this.hymn});

  @override
  State<_HymnDetailSheet> createState() => _HymnDetailSheetState();
}

enum LyricMode { dual, nepali, english }

class _HymnDetailSheetState extends State<_HymnDetailSheet> {
  LyricMode _mode = LyricMode.dual;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.churchColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.churchColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${widget.hymn.hymnNumber}',
                      style: AppTheme.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.churchColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hymn.titleEn,
                          style: AppTheme.serif(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: context.churchColors.text,
                          ),
                        ),
                        if (widget.hymn.titleNe.isNotEmpty)
                          Text(
                            widget.hymn.titleNe,
                            style: AppTheme.sans(
                              fontSize: 13,
                              color: context.churchColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.churchColors.border.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SegmentedButton<LyricMode>(
                segments: [
                  ButtonSegment(
                    value: LyricMode.dual,
                    label: Text(
                      'Dual / Side',
                      style: AppTheme.sans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ButtonSegment(
                    value: LyricMode.nepali,
                    label: Text(
                      'नेपाली (Ne)',
                      style: AppTheme.sans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ButtonSegment(
                    value: LyricMode.english,
                    label: Text(
                      'English (En)',
                      style: AppTheme.sans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) => setState(() => _mode = set.first),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  if (_mode == LyricMode.dual) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.hymn.lyricsNe.isNotEmpty
                                ? widget.hymn.lyricsNe
                                : 'No Nepali lyrics available.',
                            style: AppTheme.serif(
                              fontSize: 15,
                              height: 1.65,
                              color: context.churchColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 1,
                          color: context.churchColors.border.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.hymn.lyricsEn.isNotEmpty
                                ? widget.hymn.lyricsEn
                                : 'No English lyrics available.',
                            style: AppTheme.serif(
                              fontSize: 15,
                              height: 1.65,
                              color: context.churchColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_mode == LyricMode.nepali) ...[
                    Text(
                      widget.hymn.lyricsNe.isNotEmpty
                          ? widget.hymn.lyricsNe
                          : 'No Nepali lyrics available.',
                      style: AppTheme.serif(
                        fontSize: 16.5,
                        height: 1.75,
                        color: context.churchColors.text,
                      ),
                    ),
                  ] else ...[
                    Text(
                      widget.hymn.lyricsEn.isNotEmpty
                          ? widget.hymn.lyricsEn
                          : 'No English lyrics available.',
                      style: AppTheme.serif(
                        fontSize: 16.5,
                        height: 1.75,
                        color: context.churchColors.text,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
