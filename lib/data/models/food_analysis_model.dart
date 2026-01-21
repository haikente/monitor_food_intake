import 'dart:convert';
import '../../domain/entities/food_analysis_entity.dart';
import '../../domain/entities/food_item_entity.dart';
import 'food_item_model.dart';

/// Model extends Entity và thêm serialization cho SQLite
class FoodAnalysisModel extends FoodAnalysisEntity {
  FoodAnalysisModel({
    required super.id,
    required super.foods,
    required super.timestamp,
    super.imagePath,
    super.notes,
  });

  /// From Entity (Domain → Data)
  factory FoodAnalysisModel.fromEntity(FoodAnalysisEntity entity) {
    return FoodAnalysisModel(
      id: entity.id,
      foods: entity.foods.map((f) => FoodItemModel.fromEntity(f)).toList(),
      timestamp: entity.timestamp,
      imagePath: entity.imagePath,
      notes: entity.notes,
    );
  }

  /// To Map - Lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foods_json': jsonEncode(
        foods.map((f) => (f as FoodItemModel).toJson()).toList(),
      ),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'image_path': imagePath,
      'notes': notes,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'total_weight': totalWeight,
      'average_gi': averageGI,
      'food_count': foodCount,
      'created_at': timestamp.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// From Map - Đọc từ SQLite
  factory FoodAnalysisModel.fromMap(Map<String, dynamic> map) {
    final foodsJson = jsonDecode(map['foods_json'] as String) as List;
    final foods = foodsJson
        .map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return FoodAnalysisModel(
      id: map['id'] as String,
      foods: foods,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      imagePath: map['image_path'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// To Entity (Data → Domain)
  FoodAnalysisEntity toEntity() => this;

  /// Copy with
  @override
  FoodAnalysisModel copyWith({
    String? id,
    List<FoodItemEntity>? foods,
    DateTime? timestamp,
    String? imagePath,
    String? notes,
  }) {
    return FoodAnalysisModel(
      id: id ?? this.id,
      foods: foods != null
          ? foods.map((f) => FoodItemModel.fromEntity(f)).toList()
          : this.foods,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
    );
  }

  /// To JSON (cho export/backup)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foods': foods.map((f) => (f as FoodItemModel).toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
      'notes': notes,
      'total_calories': totalCalories,
      'average_gi': averageGI,
    };
  }

  /// From JSON (cho import/restore)
  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    final foodsJson = json['foods'] as List;
    final foods = foodsJson
        .map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return FoodAnalysisModel(
      id: json['id'] as String,
      foods: foods,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['image_path'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
