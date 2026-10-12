import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedHymns extends Table {
  IntColumn get id => integer()();
  IntColumn get hymnNumber => integer()();
  TextColumn get titleEn => text()();
  TextColumn get titleNe => text()();
  TextColumn get lyricsEn => text()();
  TextColumn get lyricsNe => text()();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();
  TextColumn get tenantKey => text()();

  @override
  Set<Column<Object>>? get primaryKey => {id, tenantKey};
}

class CachedDailyQuotes extends Table {
  IntColumn get id => integer()();
  TextColumn get content => text()();
  TextColumn get authorName => text().nullable()();
  TextColumn get dateStr => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class CachedBulletins extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  DateTimeColumn get publicationDate => dateTime()();
  TextColumn get pdfUrl => text().nullable()();
  TextColumn get contentHtml => text().nullable()();
  TextColumn get tenantKey => text()();

  @override
  Set<Column<Object>>? get primaryKey => {id, tenantKey};
}

class CachedEvents extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get section => text().withDefault(const Constant('community'))();
  IntColumn get rsvpCount => integer().withDefault(const Constant(0))();
  TextColumn get tenantKey => text()();

  @override
  Set<Column<Object>>? get primaryKey => {id, tenantKey};
}

/// The last Theme fetched for each church, kept as the backend sent it so the
/// app opens in its church's colors without waiting on the network.
class CachedThemes extends Table {
  TextColumn get tenantKey => text()();
  TextColumn get themeJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {tenantKey};
}

/// The last Service Times fetched for each church, kept as the backend sent
/// them so Home shows when the church worships while offline.
class CachedServiceTimes extends Table {
  TextColumn get tenantKey => text()();
  TextColumn get serviceTimesJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {tenantKey};
}

@DriftDatabase(
  tables: [
    CachedHymns,
    CachedDailyQuotes,
    CachedBulletins,
    CachedEvents,
    CachedThemes,
    CachedServiceTimes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedThemes);
      }
      if (from < 3) {
        await m.createTable(cachedServiceTimes);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'shalomly_db');
  }
}
