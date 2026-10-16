import 'package:equatable/equatable.dart';
import 'package:shalomly_app/src/features/events/domain/event_summary.dart';

enum GroupType {
  bibleStudy('bible_study', 'Bible Study'),
  ministry('ministry', 'Ministry'),
  choir('choir', 'Choir & Worship'),
  outreach('outreach', 'Outreach & Missions'),
  other('other', 'Fellowship');

  final String value;
  final String label;
  const GroupType(this.value, this.label);

  static GroupType fromString(String val) {
    return GroupType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => GroupType.other,
    );
  }
}

class Group extends Equatable {
  final int id;
  final int tenantId;
  final String name;
  final String? description;
  final GroupType groupType;
  final bool isOpen;
  final bool isArchived;
  final String? meetingSchedule;
  final String? meetingLocation;
  final String? materialUrl;
  final int memberCount;
  final bool isMember;
  final bool isLeader;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.groupType = GroupType.bibleStudy,
    this.isOpen = true,
    this.isArchived = false,
    this.meetingSchedule,
    this.meetingLocation,
    this.materialUrl,
    this.memberCount = 0,
    this.isMember = false,
    this.isLeader = false,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int? ?? 1,
      name: json['name'] as String,
      description: json['description'] as String?,
      groupType: GroupType.fromString(json['group_type'] as String? ?? 'bible_study'),
      isOpen: json['is_open'] as bool? ?? true,
      isArchived: json['is_archived'] as bool? ?? false,
      meetingSchedule: json['meeting_schedule'] as String?,
      meetingLocation: json['meeting_location'] as String?,
      materialUrl: json['material_url'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      isMember: json['is_member'] as bool? ?? false,
      isLeader: json['is_leader'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Group copyWith({
    bool? isMember,
    bool? isLeader,
    int? memberCount,
    bool? isOpen,
    bool? isArchived,
  }) {
    return Group(
      id: id,
      tenantId: tenantId,
      name: name,
      description: description,
      groupType: groupType,
      isOpen: isOpen ?? this.isOpen,
      isArchived: isArchived ?? this.isArchived,
      meetingSchedule: meetingSchedule,
      meetingLocation: meetingLocation,
      materialUrl: materialUrl,
      memberCount: memberCount ?? this.memberCount,
      isMember: isMember ?? this.isMember,
      isLeader: isLeader ?? this.isLeader,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        name,
        description,
        groupType,
        isOpen,
        isArchived,
        meetingSchedule,
        meetingLocation,
        materialUrl,
        memberCount,
        isMember,
        isLeader,
        createdAt,
      ];
}

class GroupMember extends Equatable {
  final int userId;
  final String? fullName;
  final bool isLeader;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    this.fullName,
    required this.isLeader,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: (json['user_id'] ?? json['id']) as int,
      fullName: json['full_name'] as String?,
      isLeader: json['is_leader'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, fullName, isLeader, joinedAt];
}

class GroupPost extends Equatable {
  final int id;
  final int groupId;
  final int authorId;
  final String? authorName;

  /// The message; a post may be only an Event, so it can be absent.
  final String? body;

  /// The Event this post shares with the Group, and its current details.
  /// [event] is null when there is no Event or it was deleted since.
  final int? eventId;
  final EventSummary? event;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    this.authorName,
    this.body,
    this.eventId,
    this.event,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    return GroupPost(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      authorId: json['author_id'] as int,
      authorName: json['author_name'] as String?,
      body: json['body'] as String?,
      eventId: json['event_id'] as int?,
      event: json['event'] == null
          ? null
          : EventSummary.fromJson(json['event'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, groupId, authorId, authorName, body, eventId, event, createdAt, updatedAt];
}
