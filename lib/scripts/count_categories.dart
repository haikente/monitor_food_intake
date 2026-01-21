import 'package:monitor_food_intake/data/database/food_database_generated.dart';

void main() {
  // Count foods by category
  final categoryCounts = <String, int>{};

  for (var food in FoodDatabaseGenerated.foods.values) {
    categoryCounts[food.category] = (categoryCounts[food.category] ?? 0) + 1;
  }

  print('📊 THỐNG KÊ MÓN ĂN VIỆT NAM:');
  print('=' * 70);
  print('Tổng số món: ${FoodDatabaseGenerated.foods.length}');
  print('=' * 70);
  print('');

  // Sort by count descending
  final sorted = categoryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (var entry in sorted) {
    print(
        '${entry.key.padRight(30)} : ${entry.value.toString().padLeft(3)} món');
  }

  print('=' * 70);
  print('');

  // List all unique categories
  print('📋 DANH SÁCH CÁC CATEGORY:');
  for (var category in categoryCounts.keys.toList()..sort()) {
    print("  '$category',");
  }
}
