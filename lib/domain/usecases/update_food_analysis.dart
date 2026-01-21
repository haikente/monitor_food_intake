import '../entities/food_analysis_entity.dart';
import '../entities/food_item_entity.dart';
import '../repositories/food_analysis_repository.dart';

/// Use Case: Cập nhật phân tích thực phẩm
class UpdateFoodAnalysisUseCase {
  final FoodAnalysisRepository repository;

  UpdateFoodAnalysisUseCase(this.repository);

  /// Cập nhật analysis
  Future<void> call(FoodAnalysisEntity analysis) async {
    // Validation
    if (analysis.foods.isEmpty) {
      throw Exception('Phân tích phải có ít nhất một món ăn');
    }

    return await repository.updateFoodAnalysis(analysis);
  }

  /// Cập nhật chỉ notes
  Future<void> updateNotes({
    required String id,
    required String notes,
  }) async {
    final existing = await repository.getFoodAnalysisById(id);
    if (existing == null) {
      throw Exception('Không tìm thấy phân tích với ID: $id');
    }

    final updated = existing.copyWith(notes: notes);
    await repository.updateFoodAnalysis(updated);
  }

  /// Cập nhật foods
  Future<void> updateFoods({
    required String id,
    required List<FoodItemEntity> foods,
  }) async {
    final existing = await repository.getFoodAnalysisById(id);
    if (existing == null) {
      throw Exception('Không tìm thấy phân tích với ID: $id');
    }

    final updated = existing.copyWith(foods: foods);
    await repository.updateFoodAnalysis(updated);
  }
}
