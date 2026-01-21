import '../../domain/entities/food_item_entity.dart';

/// Model extends Entity và thêm serialization cho SQLite/JSON
class FoodItemModel extends FoodItemEntity {
  FoodItemModel({
    required super.name,
    super.nameEn,
    required super.weight,
    required super.calories,
    super.protein,
    super.carbs,
    super.fat,
    super.fiber,
    super.glycemicIndex,
    super.category,
  });

  /// From Entity (Domain → Data)
  factory FoodItemModel.fromEntity(FoodItemEntity entity) {
    return FoodItemModel(
      name: entity.name,
      nameEn: entity.nameEn,
      weight: entity.weight,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      fiber: entity.fiber,
      glycemicIndex: entity.glycemicIndex,
      category: entity.category,
    );
  }

  /// To JSON (cho SQLite storage)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_en': nameEn,
      'weight': weight,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'glycemic_index': glycemicIndex,
      'category': category,
    };
  }

  /// From JSON (từ SQLite)
  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      weight: (json['weight'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      protein:
          json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : null,
      glycemicIndex: json['glycemic_index'] != null
          ? (json['glycemic_index'] as num).toDouble()
          : null,
      category: json['category'] as String?,
    );
  }

  /// To Entity (Data → Domain)
  FoodItemEntity toEntity() => this;

  /// Copy with
  @override
  FoodItemModel copyWith({
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
    return FoodItemModel(
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
}
