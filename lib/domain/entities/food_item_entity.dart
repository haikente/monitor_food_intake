/// Entity đại diện cho một món ăn trong bữa ăn
/// Pure Dart - Không phụ thuộc vào Flutter/SQLite
class FoodItemEntity {
  final String name;
  final String? nameEn;
  final double weight; // grams
  final double calories;
  final double? protein; // grams (nullable nếu không có data)
  final double? carbs; // grams (nullable nếu không có data)
  final double? fat; // grams (nullable nếu không có data)
  final double? fiber; // grams (nullable nếu không có data)
  final double? glycemicIndex;
  final String? category;

  FoodItemEntity({
    required this.name,
    this.nameEn,
    required this.weight,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.glycemicIndex,
    this.category,
  });

  /// Calories per 100g (calculated)
  double get caloriesPer100g {
    if (weight == 0) return 0;
    return (calories / weight) * 100;
  }

  /// Protein per 100g (nullable)
  double? get proteinPer100g {
    if (protein == null || weight == 0) return null;
    return (protein! / weight) * 100;
  }

  /// Carbs per 100g (nullable)
  double? get carbsPer100g {
    if (carbs == null || weight == 0) return null;
    return (carbs! / weight) * 100;
  }

  /// Fat per 100g (nullable)
  double? get fatPer100g {
    if (fat == null || weight == 0) return null;
    return (fat! / weight) * 100;
  }

  /// GI level description
  String get giLevel {
    if (glycemicIndex == null) return 'Không có dữ liệu';
    if (glycemicIndex! < 55) return 'Thấp';
    if (glycemicIndex! < 70) return 'Trung bình';
    return 'Cao';
  }

  /// Tạo bản sao với các trường được cập nhật
  FoodItemEntity copyWith({
    String? name,
    String? nameEn,
    double? weight,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? glycemicIndex,
    String? category,
  }) {
    return FoodItemEntity(
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      weight: weight ?? this.weight,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      glycemicIndex: glycemicIndex ?? this.glycemicIndex,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FoodItemEntity &&
        other.name == name &&
        other.nameEn == nameEn &&
        other.weight == weight;
  }

  @override
  int get hashCode {
    return name.hashCode ^ nameEn.hashCode ^ weight.hashCode;
  }

  @override
  String toString() {
    return 'FoodItemEntity(name: $name, weight: ${weight}g, '
        'calories: ${calories.toStringAsFixed(1)} kcal)';
  }
}
