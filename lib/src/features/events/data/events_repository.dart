import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

class EventsRepository {
  final Dio dio;

  EventsRepository({required this.dio});

  Future<List<ChurchEvent>> getEvents({
    DateTime? startsAfter,
    DateTime? startsBefore,
    bool includeCancelled = false,
    List<EventType>? types,
    int pageSize = 50,
    bool newestFirst = false,
  }) async {
    final response = await dio.get<dynamic>(
      ApiEndpoints.events,
      queryParameters: {
        'page': 1,
        'page_size': pageSize,
        if (types != null) 'type': [for (final type in types) type.value],
        if (startsAfter != null)
          'starts_after': startsAfter.toUtc().toIso8601String(),
        if (startsBefore != null)
          'starts_before': startsBefore.toUtc().toIso8601String(),
        'include_cancelled': includeCancelled,
        if (newestFirst) 'newest_first': true,
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

  Future<ChurchEvent> getEvent(int id) async {
    final response = await dio.get<dynamic>(ApiEndpoints.eventDetails(id));
    return ChurchEvent.fromJson(response.data as Map<String, dynamic>);
  }

  /// Saves the edit form; every field is sent, so a cleared one is cleared.
  Future<void> updateEvent(int id, EventDraft draft) async {
    await dio.patch<dynamic>(
      ApiEndpoints.eventDetails(id),
      data: draft.toUpdateJson(),
    );
  }

  /// Calls an Event off, or puts it back on the calendar.
  Future<void> setCancelled(int id, bool cancelled) async {
    await dio.patch<dynamic>(
      ApiEndpoints.eventDetails(id),
      data: {'is_cancelled': cancelled},
    );
  }

  /// Shares an Event with a Group: a Group Post that points to it.
  Future<void> shareWithGroup({required int eventId, required int groupId}) async {
    await dio.post<dynamic>(
      ApiEndpoints.groupPosts(groupId),
      data: {'event_id': eventId},
    );
  }

  Future<void> deleteEvent(int id) async {
    await dio.delete<dynamic>(ApiEndpoints.eventDetails(id));
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

  /// Posts one Event; the draft must have no [EventDraft.problems].
  Future<ChurchEvent> createEvent(EventDraft draft) async {
    final response = await dio.post<dynamic>(
      ApiEndpoints.events,
      data: draft.toCreateJson(),
    );
    return ChurchEvent.fromJson(response.data as Map<String, dynamic>);
  }
}
