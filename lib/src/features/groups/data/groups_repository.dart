import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';

class GroupsRepository {
  final Dio dio;

  GroupsRepository({required this.dio});

  Future<List<Group>> fetchGroups({bool includeArchived = false}) async {
    final response = await dio.get<dynamic>(
      ApiEndpoints.groups,
      queryParameters: {
        'page': 1,
        'page_size': 50,
        'include_archived': includeArchived,
      },
    );

    final List<dynamic> items;
    if (response.data is Map<String, dynamic> &&
        response.data['items'] != null) {
      items = response.data['items'] as List<dynamic>;
    } else if (response.data is List) {
      items = response.data as List<dynamic>;
    } else {
      items = [];
    }

    return items
        .map((item) => Group.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Group> getGroup(int groupId) async {
    final response = await dio.get<dynamic>(ApiEndpoints.groupDetails(groupId));
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
    GroupType groupType = GroupType.bibleStudy,
    bool isOpen = true,
    String? meetingSchedule,
    String? meetingLocation,
  }) async {
    final response = await dio.post<dynamic>(
      ApiEndpoints.groups,
      data: {
        'name': name,
        'description': ?description,
        'group_type': groupType.value,
        'is_open': isOpen,
        'meeting_schedule': ?meetingSchedule,
        'meeting_location': ?meetingLocation,
      },
    );
    return Group.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> joinGroup(int groupId) async {
    await dio.post<dynamic>(ApiEndpoints.groupJoin(groupId));
  }

  Future<void> leaveGroup(int groupId) async {
    await dio.post<dynamic>(ApiEndpoints.groupLeave(groupId));
  }

  Future<List<GroupMember>> getMembers(int groupId) async {
    final response = await dio.get<dynamic>(
      ApiEndpoints.groupMembers(groupId),
      queryParameters: {'page': 1, 'page_size': 50},
    );

    final List<dynamic> items;
    if (response.data is Map<String, dynamic> &&
        response.data['items'] != null) {
      items = response.data['items'] as List<dynamic>;
    } else if (response.data is List) {
      items = response.data as List<dynamic>;
    } else {
      items = [];
    }

    return items
        .map((item) => GroupMember.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addMember(int groupId, int userId) async {
    await dio.post<dynamic>(
      ApiEndpoints.groupMembers(groupId),
      data: {'user_id': userId},
    );
  }

  Future<void> removeMember(int groupId, int userId) async {
    await dio.delete<dynamic>(ApiEndpoints.groupMember(groupId, userId));
  }

  Future<void> appointLeader(int groupId, int userId) async {
    await dio.put<dynamic>(ApiEndpoints.groupLeader(groupId, userId));
  }

  Future<void> removeLeader(int groupId, int userId) async {
    await dio.delete<dynamic>(ApiEndpoints.groupLeader(groupId, userId));
  }

  Future<List<GroupPost>> getPosts(int groupId) async {
    final response = await dio.get<dynamic>(
      ApiEndpoints.groupPosts(groupId),
      queryParameters: {'page': 1, 'page_size': 50},
    );

    final List<dynamic> items;
    if (response.data is Map<String, dynamic> &&
        response.data['items'] != null) {
      items = response.data['items'] as List<dynamic>;
    } else if (response.data is List) {
      items = response.data as List<dynamic>;
    } else {
      items = [];
    }

    return items
        .map((item) => GroupPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GroupPost> createPost(int groupId, String body) async {
    final response = await dio.post<dynamic>(
      ApiEndpoints.groupPosts(groupId),
      data: {'body': body},
    );
    return GroupPost.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupPost> updatePost(int groupId, int postId, String body) async {
    final response = await dio.patch<dynamic>(
      ApiEndpoints.groupPost(groupId, postId),
      data: {'body': body},
    );
    return GroupPost.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePost(int groupId, int postId) async {
    await dio.delete<dynamic>(ApiEndpoints.groupPost(groupId, postId));
  }
}
