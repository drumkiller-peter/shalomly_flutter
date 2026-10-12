import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/announcements/domain/announcement.dart';

class AnnouncementsRepository {
  final Dio dio;

  AnnouncementsRepository({required this.dio});

  /// The church's current Announcements, newest first. Throws on failure, so
  /// the screen can say so rather than show an empty list.
  Future<List<Announcement>> fetchAnnouncements() async {
    final response = await dio.get<dynamic>(ApiEndpoints.announcements);

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
        .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
