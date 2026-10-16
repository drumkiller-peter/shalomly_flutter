import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';

/// The Groups this person may share an Event with, which is where they may
/// post: every active Group for Pastors and Admins, only the Groups they
/// lead for a Youth Leader, and none for anyone else. The backend enforces
/// the same rule.
List<Group> shareableGroups(List<Group> groups, UserRole? role) {
  if (role == null) return const [];
  final active = groups.where((g) => !g.isArchived);
  if (role.canManageContent) return active.toList();
  if (role == UserRole.youthLeader) return active.where((g) => g.isLeader).toList();
  return const [];
}
