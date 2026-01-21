import 'package:monitor_food_intake/services/semantic_food_search_service.dart';

/// TEST SEMANTIC SEARCH với database 1,275 món Việt
void main() {
  print('\n' + '═' * 60);
  print('🔍 SEMANTIC FOOD SEARCH TEST');
  print('Database: 1,275 món Việt Nam');
  print('═' * 60 + '\n');

  // Test với các query khác nhau
  final testQueries = [
    // Món Việt phổ biến
    'Phở bò Hà Nội',
    'Bún chả Hà Nội',
    'Bánh mì pate',
    'Cơm tấm sườn nướng',
    'Gỏi cuốn tôm thịt',
    
    // Món Việt đơn giản
    'Cơm trắng',
    'Thịt kho tàu',
    'Canh chua',
    
    // Món nước ngoài
    'Pizza Pepperoni',
    'Spaghetti Carbonara',
    'Hamburger',
    
    // Tên món hơi khác
    'Phở bò đặc biệt',
    'Cơm chiên dương châu',
    'Bánh mì thịt',
  ];

  int totalQueries = 0;
  int foundInDB = 0;
  int notFound = 0;

  for (final query in testQueries) {
    totalQueries++;
    print('\n📝 Query #$totalQueries: "$query"');
    print('─' * 60);

    final results = SemanticFoodSearchService.searchSemantic(
      query,
      topN: 3,
      minSimilarity: 0.3,
    );

    if (results.isEmpty) {
      notFound++;
      print('   ❌ Không tìm thấy trong database');
    } else {
      if (results.first.similarity >= 0.5) {
        foundInDB++;
        print('   ✅ Tìm thấy trong database:');
      } else {
        notFound++;
        print('   ⚠️ Match thấp (< 50%):');
      }
      
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final matchPercent = (result.similarity * 100).toStringAsFixed(1);
        final emoji = result.isExcellentMatch ? '🎯' : result.isGoodMatch ? '✅' : '⚠️';
        
        print('   $emoji ${i + 1}. ${result.matchedName} ($matchPercent%)');
        print('      Calories: ${result.food.caloriesPer100g} kcal/100g');
        print('      Protein: ${result.food.protein}g | Carbs: ${result.food.carbs}g | Fat: ${result.food.fat}g');
        print('      Category: ${result.food.category}');
      }
    }
  }

  // Summary
  print('\n' + '═' * 60);
  print('📊 SUMMARY');
  print('═' * 60);
  print('Total queries: $totalQueries');
  print('Found in DB (>= 50%): $foundInDB (${(foundInDB / totalQueries * 100).toStringAsFixed(1)}%)');
  print('Not found (< 50%): $notFound (${(notFound / totalQueries * 100).toStringAsFixed(1)}%)');
  print('═' * 60 + '\n');

  // Test best match
  print('\n' + '═' * 60);
  print('🎯 TEST BEST MATCH (Top 1 only)');
  print('═' * 60 + '\n');

  final quickTests = [
    'Phở bò',
    'Cơm tấm',
    'Bánh mì',
    'Pizza',
  ];

  for (final query in quickTests) {
    print('📝 "$query"');
    final best = SemanticFoodSearchService.searchBest(query);
    
    if (best != null) {
      print('   → ${best.matchedName} (${(best.similarity * 100).toStringAsFixed(1)}%)');
      print('   → ${best.food.caloriesPer100g} kcal/100g\n');
    } else {
      print('   → Không tìm thấy\n');
    }
  }

  print('═' * 60);
  print('✅ TEST COMPLETED');
  print('═' * 60 + '\n');
}
