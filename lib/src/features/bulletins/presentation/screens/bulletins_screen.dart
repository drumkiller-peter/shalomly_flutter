import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/bulletins/domain/bulletin.dart';
import 'package:shalomly_app/src/features/bulletins/presentation/bloc/bulletins_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class BulletinsScreen extends StatelessWidget {
  const BulletinsScreen({super.key});

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
              'Bulletins',
              style: AppTheme.serif(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.churchColors.text,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Orders of service, programs, and church documents',
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
            tooltip: 'Refresh Bulletins',
            onPressed: () {
              context.read<BulletinsBloc>().add(const RefreshBulletins());
            },
          ),
        ],
      ),
      body: BlocBuilder<BulletinsBloc, BulletinsState>(
        builder: (context, state) {
          if (state is BulletinsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BulletinsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: context.churchColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load bulletins: ${state.message}',
                      textAlign: TextAlign.center,
                      style: AppTheme.sans(color: context.churchColors.error, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.churchColors.primary,
                        foregroundColor: context.churchColors.onPrimary,
                      ),
                      onPressed: () {
                        context.read<BulletinsBloc>().add(const LoadBulletins());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is BulletinsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BulletinsBloc>().add(const RefreshBulletins());
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Header & selector, latest date first
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bulletins',
                        style: AppTheme.serif(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: context.churchColors.text,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (state.bulletins.length > 1) ...[
                        const SizedBox(width: 12),
                        // Several Bulletins can share a date, so each is named by its title.
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.churchColors.raised,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: context.churchColors.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: DropdownButton<Bulletin>(
                              isExpanded: true,
                              value: state.selectedBulletin,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: context.churchColors.primary,
                              ),
                              style: AppTheme.sans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: context.churchColors.text,
                              ),
                              items: state.bulletins.map((b) {
                                return DropdownMenuItem<Bulletin>(
                                  value: b,
                                  child: Text(
                                    '${b.title} · ${DateFormat('MMM d').format(b.weekOf)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (selected) {
                                if (selected != null) {
                                  context.read<BulletinsBloc>().add(SelectBulletin(selected));
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bulletin Detail Card
                  if (state.selectedBulletin != null)
                    _buildBulletinCard(context, state.selectedBulletin!)
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.sanctuaryCard(context.churchColors, radius: 20),
                      child: Center(
                        child: Text(
                          'No published bulletins available.',
                          style: AppTheme.sans(color: context.churchColors.textMuted),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBulletinCard(BuildContext context, Bulletin bulletin) {
    final weekStr = DateFormat('EEEE, MMMM d, yyyy').format(bulletin.weekOf);

    return Container(
      decoration: AppTheme.sanctuaryCard(context.churchColors, radius: 20),
      padding: const EdgeInsets.all(20),
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
                      Icons.auto_stories_rounded,
                      size: 13,
                      color: context.churchColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'BULLETIN',
                      style: AppTheme.trackingBadge(color: context.churchColors.primary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (bulletin.pdfUrl != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                  label: Text('PDF', style: AppTheme.sans(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => _openPdf(bulletin.pdfUrl!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bulletin.title,
            style: AppTheme.serif(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: context.churchColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weekStr,
            style: AppTheme.sans(
              fontSize: 12,
              color: context.churchColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.churchColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          if (bulletin.contentHtml != null && bulletin.contentHtml!.isNotEmpty)
            _renderBulletinContent(context, bulletin.contentHtml!)
          else
            Text(
              'This bulletin is in the attached PDF.',
              style: AppTheme.serif(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: context.churchColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderBulletinContent(BuildContext context, String html) {
    final cleanText = html
        .replaceAll(RegExp(r'<[^>]*>'), '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join('\n\n');

    return Text(
      cleanText,
      style: AppTheme.sans(
        fontSize: 13.5,
        height: 1.6,
        color: context.churchColors.text,
      ),
    );
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
