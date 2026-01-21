import '../repositories/food_analysis_repository.dart';

/// Use Case: Xóa phân tích thực phẩm
class DeleteFoodAnalysisUseCase {
  final FoodAnalysisRepository repository;

  DeleteFoodAnalysisUseCase(this.repository);

  /// Xóa một phân tích theo ID
  Future<void> call(String id) async {
    if (id.isEmpty) {
      throw Exception('ID không được để trống');
    }

    return await repository.deleteFoodAnalysis(id);
  }

  /// Xóa nhiều phân tích cùng lúc
  Future<void> deleteMultiple(List<String> ids) async {
    if (ids.isEmpty) {
      throw Exception('Danh sách IDs không được để trống');
    }

    return await repository.deleteMultipleFoodAnalyses(ids);
  }

  /// Xóa tất cả phân tích
  Future<void> deleteAll() async {
    return await repository.deleteAllFoodAnalyses();
  }
}
