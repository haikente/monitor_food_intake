import 'food_item_entity.dart';

/// Entity đại diện cho một bữa ăn đã được phân tích
/// Pure Dart - Không phụ thuộc vào Flutter/SQLite
class FoodAnalysisEntity {
  final String id;
  final List<FoodItemEntity> foods;
  final DateTime timestamp;
  final String? imagePath;
  final String? notes;

  FoodAnalysisEntity({
    required this.id,
    required this.foods,
    required this.timestamp,
    this.imagePath,
    this.notes,
  });

  // ===== BUSINESS LOGIC =====

  /// Tổng calories của bữa ăn
  double get totalCalories {
    return foods.fold(0.0, (sum, item) => sum + item.calories);
  }

  /// Trung bình GI (chỉ tính các món có GI)
  double? get averageGI {
    final itemsWithGI = foods.where((f) => f.glycemicIndex != null).toList();
    if (itemsWithGI.isEmpty) return null;

    final total = itemsWithGI.fold<double>(
      0.0,
      (sum, item) => sum + item.glycemicIndex!,
    );
    return total / itemsWithGI.length;
  }

  /// Tổng khối lượng thực phẩm (grams)
  double get totalWeight {
    return foods.fold(0.0, (sum, item) => sum + item.weight);
  }

  /// Tổng Protein (grams)
  double get totalProtein {
    return foods.fold(0.0, (sum, item) => sum + (item.protein ?? 0.0));
  }

  /// Tổng Carbs (grams)
  double get totalCarbs {
    return foods.fold(0.0, (sum, item) => sum + (item.carbs ?? 0.0));
  }

  /// Tổng Fat (grams)
  double get totalFat {
    return foods.fold(0.0, (sum, item) => sum + (item.fat ?? 0.0));
  }

  /// Số lượng món ăn
  int get foodCount => foods.length;

  /// Lời khuyên sức khỏe dựa trên phân tích
  String get healthAdvice {
    final buffer = StringBuffer();

    // Calories advice
    if (totalCalories < 300) {
      buffer.write('🟢 Bữa ăn có lượng calo thấp. ');
    } else if (totalCalories < 600) {
      buffer.write('🟡 Bữa ăn có lượng calo vừa phải. ');
    } else {
      buffer.write('🔴 Bữa ăn có lượng calo cao. ');
    }

    // GI advice
    final avgGI = averageGI;
    if (avgGI != null) {
      if (avgGI < 55) {
        buffer.write('Chỉ số GI thấp, tốt cho kiểm soát đường huyết.');
      } else if (avgGI < 70) {
        buffer.write('Chỉ số GI trung bình, nên kết hợp với rau xanh.');
      } else {
        buffer.write('Chỉ số GI cao, nên hạn chế nếu bạn có tiểu đường.');
      }
    }

    return buffer.toString();
  }

  /// Tạo bản sao với các trường được cập nhật
  FoodAnalysisEntity copyWith({
    String? id,
    List<FoodItemEntity>? foods,
    DateTime? timestamp,
    String? imagePath,
    String? notes,
  }) {
    return FoodAnalysisEntity(
      id: id ?? this.id,
      foods: foods ?? this.foods,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FoodAnalysisEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FoodAnalysisEntity(id: $id, foods: ${foods.length}, '
        'calories: ${totalCalories.toStringAsFixed(1)}, '
        'timestamp: $timestamp)';
  }
}
