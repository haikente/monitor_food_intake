import 'package:sqflite/sqflite.dart';
import '../../models/food_analysis_model.dart';
import '../../../core/database/app_database.dart';

/// Abstract interface for local data source
abstract class FoodAnalysisLocalDataSource {
  Future<void> insertFoodAnalysis(FoodAnalysisModel model);
  Future<List<FoodAnalysisModel>> getAllFoodAnalyses({
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    bool ascending = false,
  });
  Future<FoodAnalysisModel?> getFoodAnalysisById(String id);
  Future<void> updateFoodAnalysis(FoodAnalysisModel model);
  Future<void> deleteFoodAnalysis(String id);
  Future<void> deleteMultipleFoodAnalyses(List<String> ids);
  Future<int> countFoodAnalyses();
  Future<void> deleteAllFoodAnalyses();
  Future<List<FoodAnalysisModel>> searchFoodAnalyses(String keyword);
}

/// SQLite implementation of FoodAnalysisLocalDataSource
class FoodAnalysisLocalDataSourceImpl implements FoodAnalysisLocalDataSource {
  @override
  Future<void> insertFoodAnalysis(FoodAnalysisModel model) async {
    final db = await AppDatabase.database;
    await db.insert(
      AppDatabase.tableFoodAnalyses,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ Inserted food analysis: ${model.id}');
  }

  @override
  Future<List<FoodAnalysisModel>> getAllFoodAnalyses({
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    bool ascending = false,
  }) async {
    final db = await AppDatabase.database;

    // Build WHERE clause for date filtering
    String? where;
    List<dynamic>? whereArgs;

    if (fromDate != null || toDate != null) {
      List<String> conditions = [];
      whereArgs = [];

      if (fromDate != null) {
        conditions.add('timestamp >= ?');
        whereArgs.add(fromDate.millisecondsSinceEpoch);
      }

      if (toDate != null) {
        conditions.add('timestamp <= ?');
        whereArgs.add(toDate.millisecondsSinceEpoch);
      }

      where = conditions.join(' AND ');
    }

    // Build ORDER BY clause
    String orderByColumn = sortBy ?? 'timestamp';
    String orderByDirection = ascending ? 'ASC' : 'DESC';
    String orderBy = '$orderByColumn $orderByDirection';

    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.tableFoodAnalyses,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return maps.map((map) => FoodAnalysisModel.fromMap(map)).toList();
  }

  @override
  Future<FoodAnalysisModel?> getFoodAnalysisById(String id) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.tableFoodAnalyses,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return FoodAnalysisModel.fromMap(maps.first);
  }

  @override
  Future<void> updateFoodAnalysis(FoodAnalysisModel model) async {
    final db = await AppDatabase.database;

    final rowsAffected = await db.update(
      AppDatabase.tableFoodAnalyses,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );

    if (rowsAffected == 0) {
      throw Exception('Food analysis with id ${model.id} not found');
    }

    print('✅ Updated food analysis: ${model.id}');
  }

  @override
  Future<void> deleteFoodAnalysis(String id) async {
    final db = await AppDatabase.database;

    final rowsDeleted = await db.delete(
      AppDatabase.tableFoodAnalyses,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsDeleted == 0) {
      throw Exception('Food analysis with id $id not found');
    }

    print('🗑️  Deleted food analysis: $id');
  }

  @override
  Future<void> deleteMultipleFoodAnalyses(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await AppDatabase.database;
    final batch = db.batch();

    for (var id in ids) {
      batch.delete(
        AppDatabase.tableFoodAnalyses,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
    print('🗑️  Deleted ${ids.length} food analyses');
  }

  @override
  Future<int> countFoodAnalyses() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppDatabase.tableFoodAnalyses}',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> deleteAllFoodAnalyses() async {
    final db = await AppDatabase.database;
    await db.delete(AppDatabase.tableFoodAnalyses);
    print('🗑️  Deleted all food analyses');
  }

  @override
  Future<List<FoodAnalysisModel>> searchFoodAnalyses(String keyword) async {
    final db = await AppDatabase.database;

    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.tableFoodAnalyses,
      where: 'foods_json LIKE ? OR notes LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => FoodAnalysisModel.fromMap(map)).toList();
  }
}
