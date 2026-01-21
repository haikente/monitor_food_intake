import '../entities/food_analysis_entity.dart';
import '../repositories/food_analysis_repository.dart';

/// Use Case: Lưu phân tích thực phẩm mới
/// Follows Single Responsibility Principle
class SaveFoodAnalysisUseCase {
  final FoodAnalysisRepository repository;

  SaveFoodAnalysisUseCase(this.repository);

  /// Execute the use case
  /// Returns: Future<void>
  /// Throws: Exception nếu lưu thất bại
  Future<void> call(FoodAnalysisEntity analysis) async {
    // Có thể thêm business logic validation ở đây
    if (analysis.foods.isEmpty) {
      throw Exception('Cannot save analysis with no foods');
    }

    return await repository.saveFoodAnalysis(analysis);
  }

  /// Execute với validation bổ sung
  Future<void> execute({
    required FoodAnalysisEntity analysis,
    bool allowDuplicates = true,
  }) async {
    // Business validation
    if (analysis.foods.isEmpty) {
      throw Exception('Phân tích phải có ít nhất một món ăn');
    }

    if (analysis.totalCalories <= 0) {
      throw Exception('Tổng calories phải lớn hơn 0');
    }

    // Check duplicates if needed
    if (!allowDuplicates) {
      // Could check if similar analysis exists
      // ... business logic ...
    }

    await repository.saveFoodAnalysis(analysis);
  }
}
