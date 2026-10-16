import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';

/// Whether this person may edit, cancel, or delete [event]: Pastors, Admins and
/// Super Admins any Event, a Youth Leader only the ones it posted. The backend
/// enforces the same rule; this only decides whether to show the buttons.
bool canManageEvent({
  required UserRole? role,
  required int? userId,
  required ChurchEvent event,
}) {
  if (role == null) return false;
  if (role.canManageContent) return true;
  return role == UserRole.youthLeader &&
      userId != null &&
      event.createdById == userId;
}
