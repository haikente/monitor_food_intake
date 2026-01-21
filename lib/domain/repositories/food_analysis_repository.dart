import '../entities/food_analysis_entity.dart';

/// Abstract Repository - Interface cho Data layer implement
/// Domain layer chỉ định nghĩa contract, không implement
abstract class FoodAnalysisRepository {
  /// Lưu một phân tích mới
  Future<void> saveFoodAnalysis(FoodAnalysisEntity analysis);

  /// Lấy tất cả phân tích với filter và sort options
  Future<List<FoodAnalysisEntity>> getAllFoodAnalyses({
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy, // 'timestamp' (default), 'calories'
    bool ascending,
  });

  /// Lấy một phân tích theo ID
  Future<FoodAnalysisEntity?> getFoodAnalysisById(String id);

  /// Cập nhật một phân tích (edit notes, foods, etc.)
  Future<void> updateFoodAnalysis(FoodAnalysisEntity analysis);

  /// Xóa một phân tích
  Future<void> deleteFoodAnalysis(String id);

  /// Xóa nhiều phân tích cùng lúc
  Future<void> deleteMultipleFoodAnalyses(List<String> ids);

  /// Đếm tổng số phân tích
  Future<int> countFoodAnalyses();

  /// Lấy phân tích theo khoảng thời gian
  Future<List<FoodAnalysisEntity>> getFoodAnalysesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Tìm kiếm phân tích (search trong notes hoặc food names)
  Future<List<FoodAnalysisEntity>> searchFoodAnalyses(String query);

  /// Xóa tất cả dữ liệu (dùng cho reset app)
  Future<void> deleteAllFoodAnalyses();
}
