import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/hymns/domain/hymn.dart';

class HymnsRepository {
  final Dio dio;
  final AppDatabase db;
  final AppConfig appConfig;

  HymnsRepository({
    required this.dio,
    required this.db,
    required this.appConfig,
  });

  Future<List<Hymn>> getHymns({bool forceRefresh = false}) async {
    final tenant = appConfig.tenantKey;

    // 1. Check local Drift database
    final cached = await (db.select(db.cachedHymns)
          ..where((tbl) => tbl.tenantKey.equals(tenant))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.hymnNumber)]))
        .get();

    if (!forceRefresh && cached.isNotEmpty) {
      return cached
          .map((row) => Hymn(
                id: row.id,
                hymnNumber: row.hymnNumber,
                titleEn: row.titleEn,
                titleNe: row.titleNe,
                lyricsEn: row.lyricsEn,
                lyricsNe: row.lyricsNe,
                audioUrl: row.audioUrl,
                videoUrl: row.videoUrl,
                isBookmarked: row.isBookmarked,
              ))
          .toList();
    }

    // 2. Fetch from backend
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.hymns,
        queryParameters: {'page': 1, 'page_size': 100},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = (response.data!['items'] as List<dynamic>?) ?? [];
        final hymns = items
            .map((item) => Hymn.fromJson(item as Map<String, dynamic>))
            .toList();

        // 3. Batch cache into Drift preserving existing local bookmarks
        final bookmarkedIds = cached.where((c) => c.isBookmarked).map((c) => c.id).toSet();

        await db.batch((batch) {
          batch.deleteWhere(db.cachedHymns, (tbl) => tbl.tenantKey.equals(tenant));
          batch.insertAll(
            db.cachedHymns,
            hymns.map(
              (h) => CachedHymnsCompanion.insert(
                id: h.id,
                hymnNumber: h.hymnNumber,
                titleEn: h.titleEn,
                titleNe: h.titleNe,
                lyricsEn: h.lyricsEn,
                lyricsNe: h.lyricsNe,
                audioUrl: Value(h.audioUrl),
                videoUrl: Value(h.videoUrl),
                isBookmarked: Value(bookmarkedIds.contains(h.id)),
                tenantKey: tenant,
              ),
            ),
          );
        });

        return hymns
            .map((h) => h.copyWith(isBookmarked: bookmarkedIds.contains(h.id)))
            .toList();
      }
    } catch (_) {
      if (cached.isNotEmpty) {
        return cached
            .map((row) => Hymn(
                  id: row.id,
                  hymnNumber: row.hymnNumber,
                  titleEn: row.titleEn,
                  titleNe: row.titleNe,
                  lyricsEn: row.lyricsEn,
                  lyricsNe: row.lyricsNe,
                  audioUrl: row.audioUrl,
                  videoUrl: row.videoUrl,
                  isBookmarked: row.isBookmarked,
                ))
            .toList();
      }
    }

    return [];
  }

  Future<void> toggleBookmark(int hymnId, bool isBookmarked) async {
    final tenant = appConfig.tenantKey;
    await (db.update(db.cachedHymns)
          ..where((tbl) => tbl.id.equals(hymnId) & tbl.tenantKey.equals(tenant)))
        .write(CachedHymnsCompanion(isBookmarked: Value(isBookmarked)));
  }
}
