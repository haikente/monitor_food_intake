import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite Database Manager - Singleton
class AppDatabase {
  static Database? _database;
  static const String _databaseName = 'food_monitor.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableFoodAnalyses = 'food_analyses';

  /// Get database instance (Singleton pattern)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  static Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);

    print('📁 Database path: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        print('✅ Database opened successfully');
      },
    );
  }

  /// Create tables when database is created for the first time
  static Future<void> _onCreate(Database db, int version) async {
    print('🔨 Creating database tables...');

    // Create food_analyses table
    await db.execute('''
      CREATE TABLE $tableFoodAnalyses (
        id TEXT PRIMARY KEY,
        foods_json TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        image_path TEXT,
        notes TEXT,
        total_calories REAL NOT NULL,
        total_protein REAL NOT NULL,
        total_carbs REAL NOT NULL,
        total_fat REAL NOT NULL,
        total_weight REAL NOT NULL,
        average_gi REAL,
        food_count INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_timestamp 
      ON $tableFoodAnalyses(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_calories 
      ON $tableFoodAnalyses(total_calories DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_created_at 
      ON $tableFoodAnalyses(created_at DESC)
    ''');

    print('✅ Database tables created successfully');
  }

  /// Handle database upgrades (migrations)
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('⬆️  Upgrading database from v$oldVersion to v$newVersion');

    // Example migration for version 2
    if (oldVersion < 2) {
      // await db.execute('ALTER TABLE $tableFoodAnalyses ADD COLUMN new_column TEXT');
    }

    // Add more migrations as needed
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 Database closed');
    }
  }

  /// Clear all data (useful for testing/reset)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableFoodAnalyses);
    print('🗑️  All data cleared');
  }

  /// Delete database file (complete reset)
  static Future<void> deleteDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('💥 Database deleted');
  }

  /// Get database info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final path = join(await getDatabasesPath(), _databaseName);
    final version = await db.getVersion();
    final isOpen = db.isOpen;

    // Count records
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableFoodAnalyses',
    );
    final recordCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get database size (if available)
    final file = await databaseFactory.databaseExists(path);

    return {
      'path': path,
      'version': version,
      'isOpen': isOpen,
      'recordCount': recordCount,
      'exists': file,
      'tableName': tableFoodAnalyses,
    };
  }

  /// Backup database (export to JSON)
  static Future<List<Map<String, dynamic>>> exportAllData() async {
    final db = await database;
    return await db.query(tableFoodAnalyses);
  }

  /// Restore database (import from JSON)
  static Future<void> importData(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();

    for (var record in data) {
      batch.insert(
        tableFoodAnalyses,
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('✅ Imported ${data.length} records');
  }
}
