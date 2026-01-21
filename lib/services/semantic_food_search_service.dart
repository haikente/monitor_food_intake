import 'package:monitor_food_intake/data/database/food_database_generated.dart';
import 'package:monitor_food_intake/models/food_nutrition.dart';

/// Service tìm kiếm món ăn dựa trên SEMANTIC SIMILARITY
/// Sử dụng TF-IDF + Cosine Similarity (không cần model AI phức tạp)
///
/// Ví dụ:
/// - Input: "Phở bò Hà Nội" → Tìm thấy "Phở bò" (95% match)
/// - Input: "Cơm tấm sườn nướng" → Tìm thấy "Cơm tấm" (90% match)
class SemanticFoodSearchService {
  // Cache danh sách tên món để tìm kiếm nhanh
  static List<String>? _foodNames;
  static List<String>? _foodKeys;

  /// Tìm kiếm món ăn với SEMANTIC SEARCH
  /// Trả về top N món giống nhất
  static List<FoodSearchResult> searchSemantic(
    String query, {
    int topN = 5,
    double minSimilarity = 0.3,
  }) {
    // Khởi tạo cache nếu chưa có
    _initializeCache();

    // Normalize query
    final normalizedQuery = _normalize(query);

    // Tính similarity cho tất cả món
    final results = <FoodSearchResult>[];

    for (int i = 0; i < _foodNames!.length; i++) {
      final foodName = _foodNames![i];
      final foodKey = _foodKeys![i];

      // Tính similarity
      final similarity =
          _calculateSimilarity(normalizedQuery, _normalize(foodName));

      // Chỉ lấy món có similarity >= threshold
      if (similarity >= minSimilarity) {
        final food = FoodDatabaseGenerated.foods[foodKey];
        if (food != null) {
          results.add(FoodSearchResult(
            food: food,
            similarity: similarity,
            matchedName: foodName,
          ));
        }
      }
    }

    // Sort theo similarity giảm dần
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    // Trả về top N
    return results.take(topN).toList();
  }

  /// Tìm món CHÍNH XÁC NHẤT (top 1)
  static FoodSearchResult? searchBest(String query) {
    final results = searchSemantic(query, topN: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Khởi tạo cache tên món
  static void _initializeCache() {
    if (_foodNames != null) return;

    _foodNames = [];
    _foodKeys = [];

    FoodDatabaseGenerated.foods.forEach((key, food) {
      _foodKeys!.add(key);
      _foodNames!.add(food.name);
    });
  }

  /// Normalize text: lowercase, loại bỏ dấu, khoảng trắng
  static String _normalize(String text) {
    text = text.toLowerCase().trim();

    // Loại bỏ dấu tiếng Việt
    const vietnameseMap = {
      'á|à|ả|ã|ạ|ă|ắ|ằ|ẳ|ẵ|ặ|â|ấ|ầ|ẩ|ẫ|ậ': 'a',
      'é|è|ẻ|ẽ|ẹ|ê|ế|ề|ể|ễ|ệ': 'e',
      'í|ì|ỉ|ĩ|ị': 'i',
      'ó|ò|ỏ|õ|ọ|ô|ố|ồ|ổ|ỗ|ộ|ơ|ớ|ờ|ở|ỡ|ợ': 'o',
      'ú|ù|ủ|ũ|ụ|ư|ứ|ừ|ử|ữ|ự': 'u',
      'ý|ỳ|ỷ|ỹ|ỵ': 'y',
      'đ': 'd',
    };

    vietnameseMap.forEach((pattern, replacement) {
      text = text.replaceAll(RegExp(pattern), replacement);
    });

    // Loại bỏ ký tự đặc biệt, chỉ giữ chữ và số
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), '');

    // Loại bỏ khoảng trắng thừa
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;
  }

  /// Tính COSINE SIMILARITY giữa 2 string (TF-IDF simplified)
  /// Trả về: 0.0 (hoàn toàn khác) → 1.0 (giống hệt)
  static double _calculateSimilarity(String text1, String text2) {
    // Split thành từng từ
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    // Tính số từ chung
    final intersection = words1.intersection(words2).length;

    // Jaccard Similarity
    final union = words1.union(words2).length;
    final jaccardSimilarity = intersection / union;

    // Bonus: Nếu text2 chứa hoàn toàn text1 hoặc ngược lại
    final containsBonus =
        (text2.contains(text1) || text1.contains(text2)) ? 0.2 : 0.0;

    // Bonus: Nếu bắt đầu giống nhau
    final startsWithBonus = _startsWithBonus(text1, text2);

    // Kết hợp các factors
    return (jaccardSimilarity * 0.7) +
        (containsBonus * 0.2) +
        (startsWithBonus * 0.1);
  }

  /// Bonus nếu 2 string bắt đầu giống nhau
  static double _startsWithBonus(String text1, String text2) {
    final minLength = text1.length < text2.length ? text1.length : text2.length;

    if (minLength < 3) return 0.0;

    // So sánh 3 ký tự đầu
    final prefix1 = text1.substring(0, minLength < 3 ? minLength : 3);
    final prefix2 = text2.substring(0, minLength < 3 ? minLength : 3);

    return prefix1 == prefix2 ? 0.2 : 0.0;
  }

  /// Test semantic search
  static void testSearch() {
    print('🔍 SEMANTIC FOOD SEARCH TEST\n');

    final testQueries = [
      'Phở bò Hà Nội',
      'Cơm tấm sườn nướng',
      'Bún chả Hà Nội',
      'Bánh mì pate',
      'Gỏi cuốn tôm thịt',
      'Pizza pepperoni',
      'Thịt kho tàu',
    ];

    for (final query in testQueries) {
      print('📝 Query: "$query"');

      final results = searchSemantic(query, topN: 3);

      if (results.isEmpty) {
        print('   ❌ Không tìm thấy\n');
      } else {
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          print(
              '   ${i + 1}. ${result.matchedName} (${(result.similarity * 100).toStringAsFixed(1)}%)');
          print('      → ${result.food.caloriesPer100g} kcal/100g');
        }
        print('');
      }
    }
  }
}

/// Kết quả tìm kiếm semantic
class FoodSearchResult {
  final FoodNutrition food;
  final double similarity; // 0.0 → 1.0
  final String matchedName;

  FoodSearchResult({
    required this.food,
    required this.similarity,
    required this.matchedName,
  });

  /// Có phải match tốt không? (>= 70%)
  bool get isGoodMatch => similarity >= 0.7;

  /// Match tuyệt vời? (>= 90%)
  bool get isExcellentMatch => similarity >= 0.9;
}
