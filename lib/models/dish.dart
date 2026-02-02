import 'food_item.dart';

/// Model đại diện cho một món ăn (có thể chứa nhiều thành phần)
class Dish {
  final String dishName; // Tên món ăn tổng thể (VD: "Phở bò", "Cơm tấm")
  final List<FoodItem> ingredients; // Danh sách thành phần
  final String? imageUrl; // URL ảnh món ăn (nếu có)
  final DateTime timestamp;

  Dish({
    required this.dishName,
    required this.ingredients,
    this.imageUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Tổng calories của món ăn
  double get totalCalories {
    return ingredients.fold(0, (sum, item) => sum + item.calories);
  }

  // Tổng khối lượng của món ăn
  double get totalWeight {
    return ingredients.fold(0, (sum, item) => sum + item.weight);
  }

  // Trung bình GI của món ăn
  double? get averageGI {
    final itemsWithGI =
        ingredients.where((f) => f.glycemicIndex != null).toList();
    if (itemsWithGI.isEmpty) return null;

    final total =
        itemsWithGI.fold<double>(0, (sum, item) => sum + item.glycemicIndex!);
    return total / itemsWithGI.length;
  }

  // Tổng dinh dưỡng (đã tính theo khối lượng thực tế)
  Map<String, double> get totalNutrition {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;

    for (var ingredient in ingredients) {
      if (ingredient.protein != null) {
        totalProtein += ingredient.protein! * ingredient.weight / 100;
      }
      if (ingredient.carbs != null) {
        totalCarbs += ingredient.carbs! * ingredient.weight / 100;
      }
      if (ingredient.fat != null) {
        totalFat += ingredient.fat! * ingredient.weight / 100;
      }
      if (ingredient.fiber != null) {
        totalFiber += ingredient.fiber! * ingredient.weight / 100;
      }
    }

    return {
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'dishName': dishName,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Parse from JSON
  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      dishName: json['dishName'] as String,
      ingredients: (json['ingredients'] as List)
          .map((i) => FoodItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Copy with modifications
  Dish copyWith({
    String? dishName,
    List<FoodItem>? ingredients,
    String? imageUrl,
    DateTime? timestamp,
  }) {
    return Dish(
      dishName: dishName ?? this.dishName,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
