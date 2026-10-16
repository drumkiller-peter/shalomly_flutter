import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/features/groups/data/groups_repository.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';
import 'package:shalomly_app/src/features/groups/presentation/widgets/shared_event_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Group _currentGroup;
  List<GroupPost> _posts = [];
  List<GroupMember> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    _tabController = TabController(length: 2, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<GroupsRepository>();
      final freshGroup = await repo.getGroup(_currentGroup.id);
      final posts = await repo.getPosts(_currentGroup.id);
      final members = await repo.getMembers(_currentGroup.id);

      if (mounted) {
        setState(() {
          _currentGroup = freshGroup;
          _posts = posts;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _isLeaderOrManagement(AuthState authState) {
    if (authState is! Authenticated) return false;
    final user = authState.user;
    return _currentGroup.isLeader || user.role.canManageContent;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final canLead = _isLeaderOrManagement(authState);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _currentGroup.name,
              style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadGroupData,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Group Posts'),
                Tab(text: 'Members'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: context.churchColors.error),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load group content: $_errorMessage',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.churchColors.text),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: _loadGroupData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(context, authState, canLead),
                        _buildMembersTab(context, authState, canLead),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildPostsTab(BuildContext context, AuthState authState, bool canLead) {
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGroupHeaderCard(context),
        const SizedBox(height: 16),
        if (canLead && !_currentGroup.isArchived)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.churchColors.primary,
                foregroundColor: context.churchColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text('Post in Group'),
              onPressed: () => _showCreatePostDialog(context),
            ),
          ),
        if (_posts.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.forum_outlined,
                    size: 44, color: context.churchColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  'No Group Posts yet.',
                  style: TextStyle(color: context.churchColors.textMuted),
                ),
              ],
            ),
          )
        else
          ..._posts.map((post) {
            final isAuthor = currentUserId == post.authorId;
            final canDelete = canLead || isAuthor;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sanctuaryCard(context.churchColors),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.authorName ?? 'Group Member',
                        style: AppTheme.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.churchColors.primary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat.yMMMd().format(post.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.churchColors.textMuted,
                            ),
                          ),
                          if (isAuthor || canDelete) ...[
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded,
                                  size: 16, color: context.churchColors.textMuted),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditPostDialog(context, post);
                                } else if (val == 'delete') {
                                  _deletePost(post.id);
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (isAuthor)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Post'),
                                  ),
                                if (canDelete)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Post'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (post.body != null && post.body!.isNotEmpty)
                    Text(
                      post.body!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: context.churchColors.text,
                      ),
                    ),
                  if (post.event != null) ...[
                    if (post.body != null && post.body!.isNotEmpty)
                      const SizedBox(height: 10),
                    SharedEventCard(event: post.event!),
                  ] else if (post.eventId != null &&
                      (post.body == null || post.body!.isEmpty))
                    Text(
                      TranslationString.eventNoLongerOnCalendar.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: context.churchColors.textMuted,
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMembersTab(BuildContext context, AuthState authState, bool canLead) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canLead && !_currentGroup.isArchived) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add Member to Group'),
              onPressed: () => _showAddMemberDialog(context),
            ),
          ),
        ],
        if (_members.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Text(
              'No members listed.',
              style: TextStyle(color: context.churchColors.textMuted),
            ),
          )
        else
          ..._members.map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: AppTheme.sanctuaryCard(context.churchColors),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.churchColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      m.fullName?.isNotEmpty == true
                          ? m.fullName![0].toUpperCase()
                          : '#${m.userId}',
                      style: TextStyle(
                        color: context.churchColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.fullName ?? 'Member #${m.userId}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.churchColors.text,
                          ),
                        ),
                        if (m.isLeader)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
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
                  if (canLead && !_currentGroup.isArchived)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded,
                          size: 18, color: context.churchColors.textMuted),
                      onSelected: (val) {
                        if (val == 'appoint_leader') {
                          _appointLeader(m.userId);
                        } else if (val == 'remove_leader') {
                          _removeLeader(m.userId);
                        } else if (val == 'remove_member') {
                          _removeMember(m.userId);
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (!m.isLeader)
                          const PopupMenuItem(
                            value: 'appoint_leader',
                            child: Text('Appoint Group Leader'),
                          )
                        else
                          const PopupMenuItem(
                            value: 'remove_leader',
                            child: Text('Remove as Group Leader'),
                          ),
                        const PopupMenuItem(
                          value: 'remove_member',
                          child: Text('Remove Member'),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildGroupHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sanctuaryCard(context.churchColors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.churchColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentGroup.groupType.label.toUpperCase(),
                  style: AppTheme.trackingBadge(
                    color: context.churchColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _currentGroup.isOpen
                      ? context.churchColors.success.withValues(alpha: 0.12)
                      : context.churchColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentGroup.isOpen ? 'OPEN GROUP' : 'CLOSED GROUP',
                  style: AppTheme.trackingBadge(
                    color: _currentGroup.isOpen
                        ? context.churchColors.success
                        : context.churchColors.warning,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (_currentGroup.description != null) ...[
            const SizedBox(height: 10),
            Text(
              _currentGroup.description!,
              style: TextStyle(
                fontSize: 13.5,
                color: context.churchColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
          if (_currentGroup.meetingSchedule != null ||
              _currentGroup.meetingLocation != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (_currentGroup.meetingSchedule != null) ...[
                  Icon(Icons.access_time_rounded,
                      size: 14, color: context.churchColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _currentGroup.meetingSchedule!,
                    style: TextStyle(fontSize: 12, color: context.churchColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                ],
                if (_currentGroup.meetingLocation != null) ...[
                  Icon(Icons.location_on_rounded,
                      size: 14, color: context.churchColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _currentGroup.meetingLocation!,
                    style: TextStyle(fontSize: 12, color: context.churchColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final bodyController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Group Post'),
        content: TextField(
          controller: bodyController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Share a message, scripture, or update with your group...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final body = bodyController.text.trim();
              if (body.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await context.read<GroupsRepository>().createPost(_currentGroup.id, body);
                  await _loadGroupData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to publish post: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showEditPostDialog(BuildContext context, GroupPost post) {
    final bodyController = TextEditingController(text: post.body);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group Post'),
        content: TextField(
          controller: bodyController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Edit post content...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final body = bodyController.text.trim();
              if (body.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await context.read<GroupsRepository>().updatePost(_currentGroup.id, post.id, body);
                  await _loadGroupData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update post: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    try {
      await context.read<GroupsRepository>().deletePost(_currentGroup.id, postId);
      await _loadGroupData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  void _showAddMemberDialog(BuildContext context) {
    final idController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member to Group'),
        content: TextField(
          controller: idController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Member User ID',
            hintText: 'Enter user ID of church member',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final userId = int.tryParse(idController.text.trim());
              if (userId != null) {
                Navigator.pop(ctx);
                try {
                  await context.read<GroupsRepository>().addMember(_currentGroup.id, userId);
                  await _loadGroupData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add member: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(int userId) async {
    try {
      await context.read<GroupsRepository>().removeMember(_currentGroup.id, userId);
      await _loadGroupData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }

  Future<void> _appointLeader(int userId) async {
    try {
      await context.read<GroupsRepository>().appointLeader(_currentGroup.id, userId);
      await _loadGroupData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to appoint Group Leader: $e')),
        );
      }
    }
  }

  Future<void> _removeLeader(int userId) async {
    try {
      await context.read<GroupsRepository>().removeLeader(_currentGroup.id, userId);
      await _loadGroupData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove Group Leader: $e')),
        );
      }
    }
  }
}
