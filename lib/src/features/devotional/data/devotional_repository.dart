import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shalomly_app/src/core/database/app_database.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/features/devotional/domain/daily_quote.dart';

class DevotionalRepository {
  final Dio dio;
  final AppDatabase db;

  DevotionalRepository({required this.dio, required this.db});

  Future<List<DailyQuote>> getDailyQuotes({bool forceRefresh = false}) async {
    // 1. Read from local cache first
    final cached = await db.select(db.cachedDailyQuotes).get();
    if (!forceRefresh && cached.isNotEmpty) {
      return cached.map(_fromRow).toList();
    }

    // 2. Fetch fresh catalogue from backend
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.dailyQuotes,
        queryParameters: {'page': 1, 'page_size': 20},
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = (response.data!['items'] as List<dynamic>?) ?? [];
        final quotes = items
            .map((item) => DailyQuote.fromJson(item as Map<String, dynamic>))
            .toList();

        // 3. Cache into Drift SQLite
        await db.batch((batch) {
          batch.deleteAll(db.cachedDailyQuotes);
          batch.insertAll(
            db.cachedDailyQuotes,
            quotes.map(
              (q) => CachedDailyQuotesCompanion.insert(
                id: Value(q.id),
                content: q.content,
                authorName: Value(q.authorName),
                dateStr: Value(q.date),
                imageUrl: Value(q.imageUrl),
              ),
            ),
          );
        });

        if (quotes.isNotEmpty) return quotes;
      }
    } catch (_) {
      // Network failed: fall through to the cache below
    }

    // 4. Fallback: stale cache, then hard-coded default
    if (cached.isNotEmpty) {
      return cached.map(_fromRow).toList();
    }
    return const [DailyQuote.fallback];
  }

  DailyQuote _fromRow(CachedDailyQuote row) => DailyQuote(
    id: row.id,
    content: row.content,
    authorName: row.authorName,
    date: row.dateStr,
    imageUrl: row.imageUrl,
  );
}
