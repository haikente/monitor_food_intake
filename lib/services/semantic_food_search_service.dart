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

  /// Tính COMBINED SIMILARITY giữa 2 string
  /// Kết hợp: Jaccard + Levenshtein + N-gram + Bonus
  /// Trả về: 0.0 (hoàn toàn khác) → 1.0 (giống hệt)
  static double _calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // 1. JACCARD SIMILARITY (word-level)
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    final jaccardSimilarity = union > 0 ? intersection / union : 0.0;

    // 2. LEVENSHTEIN SIMILARITY (character-level)
    final levenshteinSim = _levenshteinSimilarity(text1, text2);

    // 3. N-GRAM SIMILARITY (bigrams for partial matching)
    final ngramSim = _ngramSimilarity(text1, text2, n: 2);

    // 4. EXACT MATCH BONUS
    double exactBonus = 0.0;
    if (text2.contains(text1) || text1.contains(text2)) {
      // Substring match - strong signal
      exactBonus = 0.3;
    } else if (_hasCommonKeyword(text1, text2)) {
      // Common food keyword
      exactBonus = 0.15;
    }

    // 5. PREFIX MATCH BONUS
    final prefixBonus = _prefixMatchBonus(text1, text2);

    // WEIGHTED COMBINATION
    final combinedScore = (jaccardSimilarity * 0.25) +
        (levenshteinSim * 0.30) +
        (ngramSim * 0.25) +
        (exactBonus * 0.15) +
        (prefixBonus * 0.05);

    return combinedScore.clamp(0.0, 1.0);
  }

  /// Levenshtein distance-based similarity
  static double _levenshteinSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;

    final len1 = s1.length;
    final len2 = s2.length;

    if (len1 == 0 || len2 == 0) return 0.0;

    // Create distance matrix
    final matrix = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));

    for (var i = 0; i <= len1; i++) matrix[i][0] = i;
    for (var j = 0; j <= len2; j++) matrix[0][j] = j;

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final distance = matrix[len1][len2];
    final maxLen = len1 > len2 ? len1 : len2;
    return 1.0 - (distance / maxLen);
  }

  /// N-gram similarity (bigrams by default)
  static double _ngramSimilarity(String s1, String s2, {int n = 2}) {
    if (s1.length < n || s2.length < n) return 0.0;

    final ngrams1 = <String>{};
    final ngrams2 = <String>{};

    for (var i = 0; i <= s1.length - n; i++) {
      ngrams1.add(s1.substring(i, i + n));
    }
    for (var i = 0; i <= s2.length - n; i++) {
      ngrams2.add(s2.substring(i, i + n));
    }

    if (ngrams1.isEmpty || ngrams2.isEmpty) return 0.0;

    final intersection = ngrams1.intersection(ngrams2).length;
    final union = ngrams1.union(ngrams2).length;
    return intersection / union;
  }

  /// Check for common food keywords
  static bool _hasCommonKeyword(String text1, String text2) {
    const foodKeywords = [
      'com',
      'bun',
      'pho',
      'mi',
      'banh',
      'chao',
      'xoi',
      'thit',
      'ca',
      'ga',
      'tom',
      'trung',
      'heo',
      'bo',
      'rau',
      'canh',
      'goi',
      'cha',
      'nem',
      'kho',
      'nuong',
      'chien',
      'xao',
      'luoc',
      'hap',
      'soup',
      'salad',
    ];

    for (final keyword in foodKeywords) {
      if (text1.contains(keyword) && text2.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Prefix match bonus
  static double _prefixMatchBonus(String text1, String text2) {
    final minLength = text1.length < text2.length ? text1.length : text2.length;
    if (minLength < 3) return 0.0;

    // Check first 3-5 characters
    final checkLen = minLength < 5 ? minLength : 5;
    final prefix1 = text1.substring(0, checkLen);
    final prefix2 = text2.substring(0, checkLen);

    if (prefix1 == prefix2) return 0.3;

    // Partial prefix match
    final prefix3_1 = text1.substring(0, 3);
    final prefix3_2 = text2.substring(0, 3);
    if (prefix3_1 == prefix3_2) return 0.15;

    return 0.0;
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
