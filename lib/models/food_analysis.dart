import 'food_item.dart';
import 'dish.dart';
import '../domain/entities/food_analysis_entity.dart';
import '../domain/entities/food_item_entity.dart';

class FoodAnalysis {
  final List<FoodItem> foods; 
  final List<Dish>? dishes; 
  final DateTime timestamp;
  final String? imagePath;

  FoodAnalysis({
    required this.foods,
    this.dishes,
    required this.timestamp,
    this.imagePath,
  });

  double get totalCalories {
    double total = foods.fold(0, (sum, item) => sum + item.calories);
    if (dishes != null) {
      total += dishes!.fold(0, (sum, dish) => sum + dish.totalCalories);
    }
    return total;
  }

  double? get averageGI {
    final itemsWithGI = foods.where((f) => f.glycemicIndex != null).toList();
    final dishGIs = <double>[];
    if (dishes != null) {
      for (var dish in dishes!) {
        final avgGI = dish.averageGI;
        if (avgGI != null) dishGIs.add(avgGI);
      }
    }

    if (itemsWithGI.isEmpty && dishGIs.isEmpty) return null;

    double total =
        itemsWithGI.fold<double>(0, (sum, item) => sum + item.glycemicIndex!);
    total += dishGIs.fold<double>(0, (sum, gi) => sum + gi);
    return total / (itemsWithGI.length + dishGIs.length);
  }

  double get totalWeight {
    double total = foods.fold(0, (sum, item) => sum + item.weight);
    if (dishes != null) {
      total += dishes!.fold(0, (sum, dish) => sum + dish.totalWeight);
    }
    return total;
  }

  String get healthAdvice {
    final calories = totalCalories;
    final avgGI = averageGI;

    final advice = StringBuffer();

    if (calories < 300) {
      advice.write('Bữa ăn có lượng calo thấp. ');
    } else if (calories < 600) {
      advice.write('Bữa ăn có lượng calo vừa phải. ');
    } else {
      advice.write('Bữa ăn có lượng calo cao. ');
    }

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

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      foods: (json['foods'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList(),
      dishes: json['dishes'] != null
          ? (json['dishes'] as List).map((item) => Dish.fromJson(item)).toList()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foods': foods.map((f) => f.toJson()).toList(),
      'dishes': dishes?.map((d) => d.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
    };
  }

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
