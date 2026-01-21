import '../../domain/entities/food_analysis_entity.dart';
import '../../domain/repositories/food_analysis_repository.dart';
import '../datasources/local/food_analysis_local_datasource.dart';
import '../models/food_analysis_model.dart';

/// Implementation of FoodAnalysisRepository using local data source
class FoodAnalysisRepositoryImpl implements FoodAnalysisRepository {
  final FoodAnalysisLocalDataSource localDataSource;

  FoodAnalysisRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveFoodAnalysis(FoodAnalysisEntity analysis) async {
    final model = FoodAnalysisModel.fromEntity(analysis);
    await localDataSource.insertFoodAnalysis(model);
  }

  @override
  Future<List<FoodAnalysisEntity>> getAllFoodAnalyses({
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    bool ascending = false,
  }) async {
    final models = await localDataSource.getAllFoodAnalyses(
      fromDate: fromDate,
      toDate: toDate,
      sortBy: sortBy,
      ascending: ascending,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<FoodAnalysisEntity?> getFoodAnalysisById(String id) async {
    final model = await localDataSource.getFoodAnalysisById(id);
    return model?.toEntity();
  }

  @override
  Future<void> updateFoodAnalysis(FoodAnalysisEntity analysis) async {
    final model = FoodAnalysisModel.fromEntity(analysis);
    await localDataSource.updateFoodAnalysis(model);
  }

  @override
  Future<void> deleteFoodAnalysis(String id) async {
    await localDataSource.deleteFoodAnalysis(id);
  }

  @override
  Future<void> deleteMultipleFoodAnalyses(List<String> ids) async {
    await localDataSource.deleteMultipleFoodAnalyses(ids);
  }

  @override
  Future<int> countFoodAnalyses() async {
    return await localDataSource.countFoodAnalyses();
  }

  @override
  Future<List<FoodAnalysisEntity>> getFoodAnalysesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final models = await localDataSource.getAllFoodAnalyses(
      fromDate: startDate,
      toDate: endDate,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<FoodAnalysisEntity>> searchFoodAnalyses(String keyword) async {
    final models = await localDataSource.searchFoodAnalyses(keyword);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> deleteAllFoodAnalyses() async {
    await localDataSource.deleteAllFoodAnalyses();
  }
}
