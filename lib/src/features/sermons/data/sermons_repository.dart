import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/sermons/domain/sermon.dart';

class SermonsRepository {
  final Dio dio;

  SermonsRepository({required this.dio});

  Future<List<Sermon>> fetchSermons({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.sermons,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
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
          .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Offline fallback sermons
      return [
        Sermon(
          id: 1,
          tenantId: 1,
          title: 'The Sermon on the Mount: True Righteousness',
          preacher: 'Rev. Ramesh Tamang',
          preachedOn: DateTime.now().subtract(const Duration(days: 7)),
          youtubeVideoId: 'dQw4w9WgXcQ',
          description:
              'A verse-by-verse exposition of Matthew 5. Exploring Christ’s call to inward purity and divine grace.',
          thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        Sermon(
          id: 2,
          tenantId: 1,
          title: 'Walking in the Light of Fellowship',
          preacher: 'Pastor Kishor Rai',
          preachedOn: DateTime.now().subtract(const Duration(days: 14)),
          youtubeVideoId: 'L_LUpnjgPso',
          description:
              'First John chapter 1 study on authentic Christian community, confession, and walking in God’s truth.',
          thumbnailUrl: 'https://i.ytimg.com/vi/L_LUpnjgPso/hqdefault.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        Sermon(
          id: 3,
          tenantId: 1,
          title: 'Faith in Times of Trial',
          preacher: 'Rev. Ramesh Tamang',
          preachedOn: DateTime.now().subtract(const Duration(days: 21)),
          youtubeVideoId: '3JZ_D3ELwOQ',
          description:
              'James 1:2-12 reflections on perseverance, divine wisdom, and eternal crown of life.',
          thumbnailUrl: 'https://i.ytimg.com/vi/3JZ_D3ELwOQ/hqdefault.jpg',
          createdAt: DateTime.now().subtract(const Duration(days: 21)),
        ),
      ];
    }
  }

  Future<Sermon> fetchSermon(int id) async {
    final response = await dio.get<dynamic>('${ApiEndpoints.sermons}/$id');
    return Sermon.fromJson(response.data as Map<String, dynamic>);
  }
}
