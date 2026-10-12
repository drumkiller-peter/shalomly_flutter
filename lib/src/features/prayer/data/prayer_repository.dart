import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/prayer/domain/prayer_request.dart';

class PrayerRepository {
  final Dio dio;

  PrayerRepository({required this.dio});

  Future<List<PrayerRequest>> getPrayerChain() async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.prayerChain,
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
          .map((item) => PrayerRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PrayerRequest>> getMyPrivatePrayers() async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.privatePrayers,
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
          .map((item) => PrayerRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PrayerRequest> createPrayerRequest({
    String? title,
    required String content,
    required bool isPrivate,
    required bool isAnonymous,
    int? assignedPastorId,
  }) async {
    final Response<dynamic> response;
    if (isPrivate) {
      if (assignedPastorId == null) {
        throw ArgumentError(
          'assignedPastorId is required for Private Prayer Requests',
        );
      }
      response = await dio.post<dynamic>(
        ApiEndpoints.privatePrayers,
        data: {'content': content, 'assigned_pastor_id': assignedPastorId},
      );
    } else {
      response = await dio.post<dynamic>(
        ApiEndpoints.prayerChain,
        data: {'content': content, 'is_anonymous': isAnonymous},
      );
    }

    if (response.data != null && response.data is Map<String, dynamic>) {
      return PrayerRequest.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to create prayer request');
  }

  Future<void> toggleIntercession(int prayerId, bool intercede) async {
    if (intercede) {
      await dio.post<dynamic>(ApiEndpoints.prayerIntercessions(prayerId));
    } else {
      await dio.delete<dynamic>(ApiEndpoints.prayerIntercessions(prayerId));
    }
  }

  Future<List<PastoralPrayerNote>> getPastoralPrayers(int prayerId) async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.privatePastoralPrayers(prayerId),
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
          .map(
            (item) => PastoralPrayerNote.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
