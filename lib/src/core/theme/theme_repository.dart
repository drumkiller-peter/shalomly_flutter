import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';

/// Loads the church's Theme for the app to open in, and keeps it on the device.
class ThemeRepository {
  ThemeRepository({
    required this.dio,
    required this.db,
    required this.appConfig,
  });

  final Dio dio;
  final AppDatabase db;
  final AppConfig appConfig;

  /// The Theme to open the app in.
  ///
  /// A Theme kept from an earlier launch is used straight away. Without one --
  /// a first launch -- this waits up to [wait] for the server, then falls back
  /// to the Default Theme baked into the app. Either way a fresh copy is
  /// fetched and kept, so a Theme changed on the server shows on the next
  /// launch rather than switching colors under someone mid-session.
  Future<ChurchTheme> themeForLaunch({Duration wait = const Duration(seconds: 2)}) async {
    final kept = await _loadKept();
    final refreshed = _fetchAndKeep();
    if (kept != null) {
      unawaited(refreshed);
      return kept;
    }
    final fetched = await refreshed.timeout(wait, onTimeout: () => null);
    return fetched ?? ChurchTheme.defaults;
  }

  Future<ChurchTheme?> _loadKept() async {
    try {
      final row = await (db.select(db.cachedThemes)
            ..where((t) => t.tenantKey.equals(appConfig.tenantKey)))
          .getSingleOrNull();
      if (row == null) return null;
      return ChurchTheme.fromJson(jsonDecode(row.themeJson) as Map<String, dynamic>);
    } catch (_) {
      // A kept copy that no longer reads is as good as none.
      return null;
    }
  }

  /// Fetches the Theme and keeps it; `null` on any failure, never throws, so
  /// it is safe to leave running unawaited.
  Future<ChurchTheme?> _fetchAndKeep() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(ApiEndpoints.theme);
      final json = response.data;
      if (json == null) return null;
      // Parse before keeping, so a malformed response never replaces a good copy.
      final theme = ChurchTheme.fromJson(json);
      await _keep(json);
      return theme;
    } catch (_) {
      return null;
    }
  }

  /// Keeps [json] for the next launch. A failure here -- the web build has no
  /// local database yet -- costs only the kept copy, never the fetched Theme.
  Future<void> _keep(Map<String, dynamic> json) async {
    try {
      await db.into(db.cachedThemes).insertOnConflictUpdate(
            CachedThemesCompanion.insert(
              tenantKey: appConfig.tenantKey,
              themeJson: jsonEncode(json),
              fetchedAt: DateTime.now(),
            ),
          );
    } catch (_) {
      // Next launch simply fetches again.
    }
  }
}
