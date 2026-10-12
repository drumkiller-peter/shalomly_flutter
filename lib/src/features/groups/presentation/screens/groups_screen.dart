import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';
import 'package:shalomly_app/src/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthBloc>().state is Authenticated) {
        context.read<GroupsBloc>().add(const LoadGroups());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Groups'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 56,
                      color: context.churchColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Church Groups',
                      style: AppTheme.serif(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.churchColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Groups, fellowships, and group posts are available to signed-in church members. Please sign in to join.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.churchColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.churchColors.primary,
                        foregroundColor: context.churchColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: () => context.push(AppRoutes.login),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final canCreateGroup = authState.user.role.canCreateGroups;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Groups'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<GroupsBloc>().add(const RefreshGroups());
                },
              ),
            ],
          ),
          floatingActionButton: canCreateGroup
              ? FloatingActionButton.extended(
                  backgroundColor: context.churchColors.primary,
                  foregroundColor: context.churchColors.onPrimary,
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('New Group'),
                  onPressed: () => _showCreateGroupSheet(context),
                )
              : null,
          body: BlocConsumer<GroupsBloc, GroupsState>(
            listener: (context, state) {
              if (state is GroupsLoaded && state.membershipError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.membershipError!),
                    backgroundColor: context.churchColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is GroupsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is GroupsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: context.churchColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load groups: ${state.message}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.churchColors.text),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            context.read<GroupsBloc>().add(const LoadGroups());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is GroupsLoaded) {
                return Column(
                  children: [
                    // Filter chips
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All Fellowships'),
                              selected: state.selectedType == null,
                              onSelected: (_) {
                                context
                                    .read<GroupsBloc>()
                                    .add(const FilterGroupsByType(null));
                              },
                            ),
                          ),
                          ...GroupType.values.map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(type.label),
                                selected: state.selectedType == type,
                                onSelected: (_) {
                                  context.read<GroupsBloc>().add(
                                        FilterGroupsByType(
                                          state.selectedType == type ? null : type,
                                        ),
                                      );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Groups list
                    Expanded(
                      child: state.filteredGroups.isEmpty
                          ? const Center(
                              child: Text('No groups found for this category.'),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                context
                                    .read<GroupsBloc>()
                                    .add(const RefreshGroups());
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.filteredGroups.length,
                                itemBuilder: (context, index) {
                                  final group = state.filteredGroups[index];
                                  return _buildGroupCard(context, group);
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
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group) {
    final theme = Theme.of(context);
    final badgeColor = _getGroupTypeColor(context, group.groupType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.sanctuaryCard(context.churchColors),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(AppRoutes.groupDetail(group.id), extra: group);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title & badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: AppTheme.serif(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: context.churchColors.text,
                            ),
                          ),
                          if (group.isLeader)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.churchColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'GROUP LEADER',
                                style: AppTheme.trackingBadge(
                                  color: context.churchColors.secondary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!group.isOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.churchColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: context.churchColors.warning.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'CLOSED',
                              style: AppTheme.trackingBadge(
                                color: context.churchColors.warning,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: badgeColor.withAlpha(100)),
                          ),
                          child: Text(
                            group.groupType.label.toUpperCase(),
                            style: AppTheme.trackingBadge(color: badgeColor, fontSize: 9.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (group.description != null && group.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    group.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Meeting schedule & location
                if (group.meetingSchedule != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: context.churchColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            group.meetingSchedule!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (group.meetingLocation != null)
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: context.churchColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.meetingLocation!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                Divider(height: 24, color: context.churchColors.border.withValues(alpha: 0.5)),

                // Action row: Member count + Join/Leave button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 18, color: context.churchColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${group.memberCount} members',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (group.materialUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.menu_book, size: 16),
                              label: const Text('Study Material'),
                              onPressed: () => _openUrl(group.materialUrl!),
                            ),
                          ),
                        if (group.isMember)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.churchColors.error,
                              side: BorderSide(color: context.churchColors.error.withValues(alpha: 0.5)),
                            ),
                            onPressed: () {
                              context
                                  .read<GroupsBloc>()
                                  .add(ToggleGroupMembership(group.id));
                            },
                            child: const Text('Leave Group'),
                          )
                        else if (group.isOpen)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: context.churchColors.primary,
                              foregroundColor: context.churchColors.onPrimary,
                            ),
                            onPressed: () {
                              context
                                  .read<GroupsBloc>()
                                  .add(ToggleGroupMembership(group.id));
                            },
                            child: const Text('Join Group'),
                          )
                        else
                          Text(
                            'Closed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.churchColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGroupTypeColor(BuildContext context, GroupType type) {
    switch (type) {
      case GroupType.bibleStudy:
        return context.churchColors.primary;
      case GroupType.choir:
        return context.churchColors.warning;
      case GroupType.outreach:
        return context.churchColors.secondary;
      case GroupType.ministry:
        return context.churchColors.info;
      case GroupType.other:
        return context.churchColors.error;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCreateGroupSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final scheduleController = TextEditingController();
    final locationController = TextEditingController();
    GroupType selectedType = GroupType.bibleStudy;
    bool isOpen = true;

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
                    'Create New Group',
                    style: AppTheme.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.churchColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Group Name *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GroupType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Group Type'),
                    items: GroupType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Open Group (Anyone can join)'),
                    contentPadding: EdgeInsets.zero,
                    value: isOpen,
                    onChanged: (val) => setModalState(() => isOpen = val),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: scheduleController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Schedule (Optional)',
                      hintText: 'e.g. Every Friday at 6:30 PM',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Location (Optional)',
                      hintText: 'e.g. Fellowship Hall',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.churchColors.primary,
                      foregroundColor: context.churchColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(ctx);
                        context.read<GroupsBloc>().add(
                              CreateGroup(
                                name: name,
                                description: descController.text.trim().isNotEmpty
                                    ? descController.text.trim()
                                    : null,
                                groupType: selectedType,
                                isOpen: isOpen,
                                meetingSchedule: scheduleController.text.trim().isNotEmpty
                                    ? scheduleController.text.trim()
                                    : null,
                                meetingLocation: locationController.text.trim().isNotEmpty
                                    ? locationController.text.trim()
                                    : null,
                              ),
                            );
                      }
                    },
                    child: const Text('Create Group'),
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
