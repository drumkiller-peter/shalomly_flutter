import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';

class EventsRepository {
  final Dio dio;

  EventsRepository({required this.dio});

  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    int? groupId,
    bool includeCancelled = false,
  }) async {
    final response = await dio.get<dynamic>(
      ApiEndpoints.events,
      queryParameters: {
        'page': 1,
        'page_size': 50,
        if (startsAfter != null)
          'starts_after': startsAfter.toUtc().toIso8601String(),
        if (startsBefore != null)
          'starts_before': startsBefore.toUtc().toIso8601String(),
        'group_id': ?groupId,
        'include_cancelled': includeCancelled,
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
        .map((item) => ChurchEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> setRsvp({
    required int eventId,
    required String status,
    int guestCount = 0,
  }) async {
    await dio.put<dynamic>(
      ApiEndpoints.eventRsvp(eventId),
      data: {'status': status, 'guest_count': guestCount},
    );
  }

  Future<void> withdrawRsvp(int eventId) async {
    await dio.delete<dynamic>(ApiEndpoints.eventRsvp(eventId));
  }

  Future<ChurchEvent> createEvent({
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? locationName,
    String? address,
    int? groupId,
  }) async {
    final response = await dio.post<dynamic>(
      ApiEndpoints.events,
      data: {
        'title': title,
        'description': ?description,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'location_name': ?locationName,
        'address': ?address,
        'group_id': ?groupId,
      },
    );
    return ChurchEvent.fromJson(response.data as Map<String, dynamic>);
  }
}
