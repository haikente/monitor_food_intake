import '../models/food_nutrition.dart';
import '../models/food_category.dart';

/// Helper class để build AI prompts từ food database
class DatabasePromptBuilder {
  /// Build prompt cho Vietnamese food database
  static String buildVietnameseFoodPrompt(Map<String, FoodNutrition> foods) {
    final buffer = StringBuffer();
    buffer.writeln('📍 MÓN ĂN VIỆT NAM (${foods.length} món):');
    buffer.writeln();

    // Sử dụng CategoryManager để đếm và sort categories
    final categoryCounts = CategoryManager.countByCategory(foods);
    final sortedCategories =
        CategoryManager.sortByPriorityAndCount(categoryCounts);
    final categoryMap = CategoryManager.getCategoryMap();

    // Kiểm tra categories chưa được định nghĩa
    final undefinedCategories = CategoryManager.findUndefinedCategories(foods);
    if (undefinedCategories.isNotEmpty) {
      print(
          '⚠️  Cảnh báo: Có ${undefinedCategories.length} categories chưa được định nghĩa trong FoodCategory enum:');
      for (var cat in undefinedCategories) {
        print('   - "$cat"');
      }
      print('Hãy thêm vào file food_category.dart');
      print('');
    }

    // Hiển thị theo từng group
    FoodCategoryGroup? currentGroup;

    for (var entry in sortedCategories) {
      final categoryName = entry.key;
      final count = entry.value;
      final categoryEnum = categoryMap[categoryName];

      // Nếu category không có trong enum, bỏ qua
      if (categoryEnum == null) {
        // Hiển thị với icon mặc định nếu không tìm thấy
        final items = _getFoodsByCategory(foods, categoryName);
        if (items.isEmpty) continue;

        buffer.writeln('🍽️ $categoryName ($count món):');
        _appendFoodItems(buffer, items, maxItems: 3);
        continue;
      }

      // Hiển thị header của group khi chuyển sang group mới
      if (currentGroup != categoryEnum.group) {
        currentGroup = categoryEnum.group;
        buffer.writeln();
        buffer.writeln(
            '═══ ${currentGroup.icon} ${currentGroup.displayName.toUpperCase()} ═══');
        buffer.writeln();
      }

      final items = _getFoodsByCategory(foods, categoryName);
      if (items.isEmpty) continue;

      buffer.writeln('${categoryEnum.label} ($count món):');
      _appendFoodItems(buffer, items, maxItems: 5);
    }

    return buffer.toString();
  }

  /// Build prompt cho USDA food database
  static String buildUsdaFoodPrompt(Map<String, FoodNutrition> foods) {
    final buffer = StringBuffer();
    buffer.writeln('🌍 MÓN ĂN QUỐC TẾ - USDA (${foods.length} món):');
    buffer.writeln();

    // Group USDA foods by category
    final categoryMap = <String, List<FoodNutrition>>{};
    for (var food in foods.values) {
      categoryMap.putIfAbsent(food.category, () => []).add(food);
    }

    final usdaCategoryIcons = {
      'Tinh bột': '🍞',
      'Protein': '🥩',
      'Rau': '🥦',
      'Trái cây': '🍌',
      'Sữa': '🧀',
      'Đậu & Hạt': '🥜',
      'Món chính': '🍕',
      'Đồ uống': '🥤',
      'Đồ ngọt': '🍰',
      'Khác': '🍽️',
    };

    // Sort categories by count (descending)
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (var entry in sortedCategories) {
      final category = entry.key;
      final items = entry.value;
      final icon = usdaCategoryIcons[category] ?? '🍽️';

      buffer.writeln('$icon $category (${items.length} món):');
      _appendFoodItems(buffer, items, maxItems: 10);
    }

    return buffer.toString();
  }

  /// Build complete prompt với cả Vietnamese và USDA
  static String buildCompletePrompt({
    required Map<String, FoodNutrition> vietnameseFoods,
    required Map<String, FoodNutrition> usdaFoods,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('DATABASE THỰC PHẨM (Calo/100g, Protein, Carbs, Fat, GI):');
    buffer.writeln('=' * 70);
    buffer.writeln();

    // Vietnamese foods
    buffer.write(buildVietnameseFoodPrompt(vietnameseFoods));

    // Separator
    buffer.writeln('=' * 70);
    buffer.writeln();

    // USDA foods
    buffer.write(buildUsdaFoodPrompt(usdaFoods));

    // Footer
    buffer.writeln('=' * 70);
    buffer.writeln(
        '📊 TỔNG: ${vietnameseFoods.length + usdaFoods.length} món ăn');
    buffer.writeln();

    return buffer.toString();
  }

  /// Helper: Lấy danh sách món ăn theo category
  static List<FoodNutrition> _getFoodsByCategory(
    Map<String, FoodNutrition> foods,
    String category,
  ) {
    return foods.values.where((food) => food.category == category).toList();
  }

  /// Helper: Append food items vào buffer
  static void _appendFoodItems(
    StringBuffer buffer,
    List<FoodNutrition> items, {
    int maxItems = 5,
  }) {
    final itemsToShow = items.take(maxItems).toList();

    for (var item in itemsToShow) {
      final gi = item.glycemicIndex?.toStringAsFixed(0) ?? 'N/A';
      buffer.writeln(
        '  • ${item.name}: ${item.caloriesPer100g.toInt()}kcal | '
        'P:${item.protein.toStringAsFixed(1)}g | '
        'C:${item.carbs.toStringAsFixed(1)}g | '
        'F:${item.fat.toStringAsFixed(1)}g | '
        'GI:$gi',
      );
    }

    if (items.length > maxItems) {
      buffer.writeln('  ... và ${items.length - maxItems} món khác');
    }
    buffer.writeln();
  }

  /// Utility: Kiểm tra và hiển thị thống kê database
  static void printDatabaseStats(
      Map<String, FoodNutrition> foods, String dbName) {
    print('\n📊 THỐNG KÊ DATABASE: $dbName');
    print('=' * 70);
    print('Tổng số món: ${foods.length}');
    print('');

    final categoryCounts = CategoryManager.countByCategory(foods);
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    print('Phân bố theo category:');
    for (var entry in sorted) {
      print(
          '  ${entry.key.padRight(40)} : ${entry.value.toString().padLeft(3)} món');
    }

    print('=' * 70);
    print('');

    // Kiểm tra undefined categories
    final undefined = CategoryManager.findUndefinedCategories(foods);
    if (undefined.isNotEmpty) {
      print('⚠️  Categories chưa được định nghĩa (${undefined.length}):');
      for (var cat in undefined) {
        print('  - "$cat"');
      }
      print('');
    }
  }
}
