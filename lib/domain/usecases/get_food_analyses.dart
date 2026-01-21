import '../entities/food_analysis_entity.dart';
import '../repositories/food_analysis_repository.dart';

/// Use Case: Lấy danh sách phân tích thực phẩm
class GetFoodAnalysesUseCase {
  final FoodAnalysisRepository repository;

  GetFoodAnalysesUseCase(this.repository);

  /// Lấy tất cả analyses với filter options
  Future<List<FoodAnalysisEntity>> call({
    DateTime? fromDate,
    DateTime? toDate,
    String sortBy = 'timestamp',
    bool ascending = false,
  }) async {
    return await repository.getAllFoodAnalyses(
      fromDate: fromDate,
      toDate: toDate,
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  /// Lấy analyses của hôm nay
  Future<List<FoodAnalysisEntity>> getTodayAnalyses() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await repository.getFoodAnalysesByDateRange(
      startOfDay,
      endOfDay,
    );
  }

  /// Lấy analyses của tuần này
  Future<List<FoodAnalysisEntity>> getThisWeekAnalyses() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return await repository.getFoodAnalysesByDateRange(
      startOfDay,
      DateTime.now(),
    );
  }

  /// Lấy analyses của tháng này
  Future<List<FoodAnalysisEntity>> getThisMonthAnalyses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return await repository.getFoodAnalysesByDateRange(
      startOfMonth,
      DateTime.now(),
    );
  }
}
