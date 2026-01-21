import 'food_item.dart';
import '../domain/entities/food_analysis_entity.dart';
import '../domain/entities/food_item_entity.dart';

/// Model đại diện cho kết quả phân tích một bữa ăn
class FoodAnalysis {
  final List<FoodItem> foods;
  final DateTime timestamp;
  final String? imagePath;

  FoodAnalysis({
    required this.foods,
    required this.timestamp,
    this.imagePath,
  });

  // Tổng calories của bữa ăn
  double get totalCalories {
    return foods.fold(0, (sum, item) => sum + item.calories);
  }

  // Trung bình GI (chỉ tính các món có GI)
  double? get averageGI {
    final itemsWithGI = foods.where((f) => f.glycemicIndex != null).toList();
    if (itemsWithGI.isEmpty) return null;

    final total =
        itemsWithGI.fold<double>(0, (sum, item) => sum + item.glycemicIndex!);
    return total / itemsWithGI.length;
  }

  // Tổng khối lượng thực phẩm
  double get totalWeight {
    return foods.fold(0, (sum, item) => sum + item.weight);
  }

  // Health advice based on analysis
  String get healthAdvice {
    final calories = totalCalories;
    final avgGI = averageGI;

    final advice = StringBuffer();

    // Calories advice
    if (calories < 300) {
      advice.write('Bữa ăn có lượng calo thấp. ');
    } else if (calories < 600) {
      advice.write('Bữa ăn có lượng calo vừa phải. ');
    } else {
      advice.write('Bữa ăn có lượng calo cao. ');
    }

    // GI advice
    if (avgGI != null) {
      if (avgGI < 55) {
        advice.write('Chỉ số GI thấp, tốt cho kiểm soát đường huyết.');
      } else if (avgGI < 70) {
        advice.write('Chỉ số GI trung bình, nên kết hợp với rau xanh.');
      } else {
        advice.write('Chỉ số GI cao, nên hạn chế nếu bạn có tiểu đường.');
      }
    }

    return advice.toString();
  }

  // Parse từ JSON
  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      foods: (json['foods'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['image_path'] as String?,
    );
  }

  // Convert sang JSON
  Map<String, dynamic> toJson() {
    return {
      'foods': foods.map((f) => f.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
    };
  }

  // Convert sang Entity (để lưu vào database qua domain layer)
  FoodAnalysisEntity toEntity({String? id, String? notes}) {
    return FoodAnalysisEntity(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: timestamp,
      imagePath: imagePath,
      foods: foods
          .map((f) => FoodItemEntity(
                name: f.name,
                nameEn: f.nameEn,
                weight: f.weight,
                calories: f.calories,
                protein: f.protein,
                carbs: f.carbs,
                fat: f.fat,
                fiber: f.fiber,
                glycemicIndex: f.glycemicIndex,
                category: f.category,
              ))
          .toList(),
      notes: notes,
    );
  }
}
