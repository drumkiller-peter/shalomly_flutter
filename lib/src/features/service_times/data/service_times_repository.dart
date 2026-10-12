import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/service_times/domain/service_time.dart';

/// Loads the church's Service Times and keeps the last copy on the device,
/// so Home still shows when the church worships while offline.
class ServiceTimesRepository {
  ServiceTimesRepository({
    required this.dio,
    required this.db,
    required this.appConfig,
  });

  final Dio dio;
  final AppDatabase db;
  final AppConfig appConfig;

  /// The church's Service Times from the server, or the last kept copy if
  /// the server can't be reached; an empty list if there is neither.
  Future<List<ServiceTime>> fetchServiceTimes() async {
    try {
      final response = await dio.get<List<dynamic>>(ApiEndpoints.serviceTimes);
      final json = response.data ?? const [];
      // Parse before keeping, so a malformed response never replaces a good copy.
      final serviceTimes = _parse(json);
      await _keep(json);
      return serviceTimes;
    } catch (_) {
      return _loadKept();
    }
  }

  List<ServiceTime> _parse(List<dynamic> json) => json
      .map((item) => ServiceTime.fromJson(item as Map<String, dynamic>))
      .toList();

  Future<List<ServiceTime>> _loadKept() async {
    try {
      final row =
          await (db.select(db.cachedServiceTimes)
                ..where((t) => t.tenantKey.equals(appConfig.tenantKey)))
              .getSingleOrNull();
      if (row == null) return const [];
      return _parse(jsonDecode(row.serviceTimesJson) as List<dynamic>);
    } catch (_) {
      // A kept copy that no longer reads is as good as none.
      return const [];
    }
  }

  /// Keeps [json] for offline use. A failure here -- the web build has no
  /// local database yet -- costs only the kept copy.
  Future<void> _keep(List<dynamic> json) async {
    try {
      await db
          .into(db.cachedServiceTimes)
          .insertOnConflictUpdate(
            CachedServiceTimesCompanion.insert(
              tenantKey: appConfig.tenantKey,
              serviceTimesJson: jsonEncode(json),
              fetchedAt: DateTime.now(),
            ),
          );
    } catch (_) {
      // The next launch simply fetches again.
    }
  }
}
