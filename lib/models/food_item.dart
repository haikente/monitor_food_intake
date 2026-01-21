import 'food_nutrition.dart';

/// Model đại diện cho một món ăn được phân tích (model chính thống nhất)
class FoodItem {
  final String name;
  final double weight; // gram
  final double calories;
  final double? glycemicIndex; // GI index (nullable)

  // Thông tin dinh dưỡng chi tiết (LƯU GIÁ TRỊ /100g, KHÔNG phải tuyệt đối)
  final double? protein; // g/100g
  final double? carbs; // g/100g
  final double? fat; // g/100g
  final double? fiber; // g/100g
  final String? category; // Phân loại: tinh bột, protein, rau, trái cây
  final String? nameEn; // Tên tiếng Anh (nếu có)

  FoodItem({
    required this.name,
    required this.weight,
    required this.calories,
    this.glycemicIndex,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.category,
    this.nameEn,
  });

  // Parse từ JSON
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      glycemicIndex: json['glycemic_index'] != null
          ? (json['glycemic_index'] as num).toDouble()
          : null,
      protein:
          json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
      category: json['category'] as String?,
      nameEn: json['name_en'] as String?,
    );
  }

  // Tạo FoodItem từ FoodNutrition (từ database)
  factory FoodItem.fromNutrition(
    FoodNutrition nutrition,
    double weight,
  ) {
    return FoodItem(
      name: nutrition.name,
      nameEn: nutrition.nameEn,
      weight: weight,
      calories: nutrition.calculateCalories(weight),
      glycemicIndex: nutrition.glycemicIndex,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      fiber: nutrition.fiber,
      category: nutrition.category,
    );
  }

  // Convert sang JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'calories': calories,
      'glycemic_index': glycemicIndex,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'category': category,
      'name_en': nameEn,
    };
  }

  // Calculate calories per 100g
  double get caloriesPer100g => (calories / weight) * 100;

  // GI level description
  String get giLevel {
    if (glycemicIndex == null) return 'Không có dữ liệu';
    if (glycemicIndex! < 55) return 'Thấp';
    if (glycemicIndex! < 70) return 'Trung bình';
    return 'Cao';
  }

  // Tính các chỉ số dinh dưỡng theo khối lượng thực tế
  // Vì protein/carbs/fat/fiber lưu giá trị /100g, cần nhân với weight
  double? get actualProtein =>
      protein != null ? (protein! * weight) / 100 : null;
  double? get actualCarbs => carbs != null ? (carbs! * weight) / 100 : null;
  double? get actualFat => fat != null ? (fat! * weight) / 100 : null;
  double? get actualFiber => fiber != null ? (fiber! * weight) / 100 : null;

  // Copy with method for editing
  FoodItem copyWith({
    String? name,
    double? weight,
    double? calories,
    double? glycemicIndex,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? category,
    String? nameEn,
  }) {
    return FoodItem(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      calories: calories ?? this.calories,
      glycemicIndex: glycemicIndex ?? this.glycemicIndex,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      category: category ?? this.category,
      nameEn: nameEn ?? this.nameEn,
    );
  }
}
