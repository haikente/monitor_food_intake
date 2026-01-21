/// Model cho thông tin dinh dưỡng của một loại thực phẩm
class FoodNutrition {
  final String name;
  final String nameEn;
  final double caloriesPer100g; // kcal/100g
  final double? glycemicIndex; // GI index
  final double protein; // g/100g
  final double carbs; // g/100g
  final double fat; // g/100g
  final double fiber; // g/100g
  final String category; // Phân loại: tinh bột, protein, rau, trái cây

  List<double>? imageEmbedding;  // MỎ NEO HÌNH ẢNH ở đây!

  FoodNutrition({
    required this.name,
    required this.nameEn,
    required this.caloriesPer100g,
    this.glycemicIndex,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    required this.category,
  });

  /// Tính calories cho một khối lượng cụ thể
  double calculateCalories(double grams) {
    return (caloriesPer100g * grams) / 100;
  }

  /// GI level
  String get giLevel {
    if (glycemicIndex == null) return 'N/A';
    if (glycemicIndex! < 55) return 'Thấp';
    if (glycemicIndex! < 70) return 'Trung bình';
    return 'Cao';
  }
}
