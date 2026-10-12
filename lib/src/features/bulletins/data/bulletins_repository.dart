import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/bulletins/domain/bulletin.dart';

class BulletinsRepository {
  final Dio dio;
  final AppDatabase database;
  final AppConfig config;

  BulletinsRepository({
    required this.dio,
    required this.database,
    required this.config,
  });

  /// Published Bulletins, latest date first; the kept copy when offline.
  Future<List<Bulletin>> fetchBulletins() async {
    try {
      final response = await dio.get<dynamic>(
        ApiEndpoints.bulletins,
        queryParameters: {'is_published': true},
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

      final bulletins = items
          .map((item) => Bulletin.fromJson(item as Map<String, dynamic>))
          .toList();

      // Cache locally into Drift SQLite
      await _cacheBulletins(bulletins);
      return bulletins;
    } catch (_) {
      // Fallback to local SQLite cache
      final cached = await (database.select(
        database.cachedBulletins,
      )..where((tbl) => tbl.tenantKey.equals(config.tenantKey))).get();

      // With no kept copy the list is empty; nothing is invented.
      return cached
          .map(
            (row) => Bulletin(
              id: row.id,
              tenantId: 1,
              title: row.title,
              weekOf: row.publicationDate,
              contentHtml: row.contentHtml,
              pdfUrl: row.pdfUrl,
              isPublished: true,
              createdAt: row.publicationDate,
            ),
          )
          .toList()
        // Latest date first, as the server sends them.
        ..sort((x, y) => y.weekOf.compareTo(x.weekOf));
    }
  }

  /// Replaces this church's kept Bulletins with [bulletins], so one that was
  /// unpublished or deleted on the server doesn't linger offline.
  Future<void> _cacheBulletins(List<Bulletin> bulletins) async {
    await database.transaction(() async {
      await (database.delete(database.cachedBulletins)
            ..where((tbl) => tbl.tenantKey.equals(config.tenantKey)))
          .go();
      for (final bulletin in bulletins) {
        await database
            .into(database.cachedBulletins)
            .insert(
              CachedBulletinsCompanion(
                id: Value(bulletin.id),
                title: Value(bulletin.title),
                publicationDate: Value(bulletin.weekOf),
                pdfUrl: Value(bulletin.pdfUrl),
                contentHtml: Value(bulletin.contentHtml),
                tenantKey: Value(config.tenantKey),
              ),
            );
      }
    });
  }
}
