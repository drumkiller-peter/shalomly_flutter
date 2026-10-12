import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/giving/presentation/bloc/giving_bloc.dart';

class ChurchWorkspaceScreen extends StatelessWidget {
  const ChurchWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Workspace',
            onPressed: () {
              context.read<GivingBloc>().add(const GivingOverviewFetchRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated || !authState.user.role.isLeadership) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, size: 64, color: context.churchColors.warning),
                    const SizedBox(height: 16),
                    Text(
                      'Church Leadership Portal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Access is restricted to verified church pastors, administrators, and treasurers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.churchColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = authState.user;
          final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              return ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Workspace Header Card
                  _buildHeaderCard(context, user, todayStr),
                  const SizedBox(height: 20),

                  // Stat Cards Grid
                  _buildStatGrid(context),
                  const SizedBox(height: 24),

                  // Main Work Area (2 Columns on wide screen, 1 column on mobile)
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildLeftColumn(context)),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildRightColumn(context)),
                      ],
                    )
                  else ...[
                    _buildLeftColumn(context),
                    const SizedBox(height: 20),
                    _buildRightColumn(context),
                  ],

                  const SizedBox(height: 40),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, User user, String todayStr) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(context.churchColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: context.churchColors.onPrimary,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'P',
                style: TextStyle(fontSize: 24, color: context.churchColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: context.churchColors.onPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.churchColors.onPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role.value.toUpperCase(),
                          style: TextStyle(color: context.churchColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        todayStr,
                        style: TextStyle(color: context.churchColors.onPrimary.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.churchColors.onPrimary,
                    foregroundColor: context.churchColors.primary,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Event'),
                  onPressed: () => context.push(AppRoutes.events),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: constraints.maxWidth > 600 ? 2.2 : 3.5,
          children: [
            _buildStatCard(context, '1,248', 'active members', context.churchColors.primary, Icons.people),
            _buildStatCard(context, '27', 'open prayer requests', context.churchColors.warning, Icons.volunteer_activism),
            _buildStatCard(context, 'NPR 84k', 'month giving receipts', context.churchColors.secondary, Icons.account_balance_wallet),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.churchColors.border.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Member Activity Section
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.churchColors.border.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Member Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Live Roster',
                      style: TextStyle(color: context.churchColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Self-registered members appear here as active tenant users. Roles remain leadership-governed.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Divider(height: 24),
                _buildMemberRow(context, 'Kishor Rai', 'Joined from white-label mobile app', 'member', context.churchColors.primary),
                _buildMemberRow(context, 'Mina Gurung', 'Choir Fellowship & Youth Committee', 'member', context.churchColors.info),
                _buildMemberRow(context, 'Rev. Ramesh Tamang', 'Senior Pastoral Team', 'pastor', context.churchColors.secondary),
                _buildMemberRow(context, 'Prakash Shrestha', 'Church Treasurer & Accounts', 'treasurer', context.churchColors.warning),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Financial Operations Section
        BlocBuilder<GivingBloc, GivingState>(
          builder: (context, state) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: context.churchColors.border.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giving & Financial Operations',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Reconcile'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ledger reconciliation dispatched.')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildOperationRow(context, 'eSewa Settlement', '12 successful gateway donations verified', 'PAID', context.churchColors.success),
                    _buildOperationRow(context, 'Khalti Callback', '2 transactions awaiting webhook confirmation', 'REVIEW', context.churchColors.warning),
                    _buildOperationRow(context, 'Manual Deposit Slips', '4 bank transfer vouchers to verify', 'PENDING', context.churchColors.secondary),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pastoral Care & Confidential Prayers
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.churchColors.border.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_clock, color: context.churchColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pastoral Prayer Pipeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Per ADR 0001, private prayer requests remain strictly confidential between author and assigned pastor.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: context.churchColors.warning,
                    foregroundColor: context.churchColors.onWarning,
                    child: const Icon(Icons.privacy_tip, size: 18),
                  ),
                  title: const Text('Assigned Requests Queue', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('8 pending pastoral notes & prayers', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.push(AppRoutes.prayer),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Quick Navigation Tiles
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.churchColors.border.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Management Tools',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildToolTile(context, Icons.newspaper, 'Weekly Bulletins', 'Publish service orders & alerts', AppRoutes.bulletins),
                _buildToolTile(context, Icons.video_library, 'Sermons & Media', 'Manage YouTube catalog', AppRoutes.sermons),
                _buildToolTile(context, Icons.group_work, 'Groups', 'Oversee group rosters', AppRoutes.groups),
                _buildToolTile(context, Icons.menu_book, 'Bilingual Hymn Book', 'Catalogue lyrics & audio', AppRoutes.hymns),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberRow(BuildContext context, String name, String detail, String role, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: badgeColor.withAlpha(30),
            foregroundColor: badgeColor,
            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(detail, style: TextStyle(color: context.churchColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withAlpha(100)),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationRow(BuildContext context, String title, String detail, String badgeText, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(detail, style: TextStyle(color: context.churchColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: ChurchColors.onColor(color), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.churchColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 13),
      onTap: () => context.push(route),
    );
  }
}
