import '../data/database/food_database_generated.dart';
import '../models/food_nutrition.dart';

/// Service để tra cứu và matching món ăn từ database
class FoodDatabaseService {
  /// Normalize text để so sánh (loại bỏ dấu, khoảng trắng thừa)
  static String _normalizeText(String text) {
    String normalized = text.toLowerCase().trim();

    // Loại bỏ dấu tiếng Việt
    const vietnameseMap = {
      'á': 'a',
      'à': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ắ': 'a',
      'ằ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ấ': 'a',
      'ầ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'é': 'e',
      'è': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ế': 'e',
      'ề': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'í': 'i',
      'ì': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ó': 'o',
      'ò': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ố': 'o',
      'ồ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ớ': 'o',
      'ờ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ứ': 'u',
      'ừ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ý': 'y',
      'ỳ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    vietnameseMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
  }

  /// Tính độ tương đồng giữa 2 chuỗi (Levenshtein distance improved)
  static double _similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final len1 = s1.length;
    final len2 = s2.length;

    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

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

  /// Tìm món ăn trong database theo tên
  static FoodNutrition? findFood(String name) {
    final normalizedInput = _normalizeText(name);

    // BƯỚC 0: Check common ingredient aliases trước
    final aliasResult = _checkIngredientAliases(name);
    if (aliasResult != null) return aliasResult;

    // BƯỚC 1: Tìm exact match với NAME field
    for (var entry in FoodDatabaseGenerated.foods.entries) {
      final normalizedFoodName = _normalizeText(entry.value.name);

      if (normalizedFoodName == normalizedInput) {
        return entry.value;
      }
    }

    // BƯỚC 2: Tìm best match với similarity > 0.65
    FoodNutrition? bestMatch;
    double bestScore = 0.65;

    for (var entry in FoodDatabaseGenerated.foods.entries) {
      final normalizedFoodName = _normalizeText(entry.value.name);
      final score = _similarity(normalizedInput, normalizedFoodName);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry.value;
      }
    }

    if (bestMatch != null) {
      return bestMatch;
    }

    // BƯỚC 3: Partial match với NAME
    for (var entry in FoodDatabaseGenerated.foods.entries) {
      final normalizedFoodName = _normalizeText(entry.value.name);

      if (normalizedFoodName.contains(normalizedInput) ||
          normalizedInput.contains(normalizedFoodName)) {
        return entry.value;
      }
    }

    // BƯỚC 4: Tìm theo KEY (fallback)
    if (FoodDatabaseGenerated.foods.containsKey(normalizedInput)) {
      return FoodDatabaseGenerated.foods[normalizedInput];
    }

    // BƯỚC 5: Fuzzy match với key
    for (var entry in FoodDatabaseGenerated.foods.entries) {
      if (entry.key.contains(normalizedInput) ||
          normalizedInput.contains(entry.key)) {
        return entry.value;
      }
    }

    // BƯỚC 6: Token-based matching - ít nhất 2 tokens trùng
    final inputTokens = normalizedInput.split(' ').where((t) => t.length > 1).toSet();
    if (inputTokens.length >= 2) {
      FoodNutrition? tokenBestMatch;
      int tokenBestCount = 1;

      for (var entry in FoodDatabaseGenerated.foods.entries) {
        final foodTokens = _normalizeText(entry.value.name).split(' ').where((t) => t.length > 1).toSet();
        final matchCount = inputTokens.intersection(foodTokens).length;

        if (matchCount > tokenBestCount) {
          tokenBestCount = matchCount;
          tokenBestMatch = entry.value;
        }
      }

      if (tokenBestMatch != null) {
        return tokenBestMatch;
      }
    }

    return null;
  }

  /// Check ingredient aliases phổ biến cho thành phần món ăn
  static FoodNutrition? _checkIngredientAliases(String name) {
    final lower = name.toLowerCase().trim();

    // Map tên thành phần ngắn → tên trong database
    const ingredientAliases = <String, List<String>>{
      // Cơm / Tinh bột
      'cơm': ['Cơm trắng', 'Cơm tẻ'],
      'cơm trắng': ['Cơm trắng', 'Cơm tẻ'],
      'cơm tấm': ['Cơm tấm'],
      'cơm chiên': ['Cơm rang'],
      'cơm rang': ['Cơm rang'],
      'xôi': ['Xôi nếp cẩm'],
      'bánh phở': ['Phở bò chín'],
      'bún': ['Bún bò Huế'],
      'miến': ['Miến gà'],
      'mì': ['Mì trứng'],
      'bánh mì': ['Bánh mỳ vuông ngọt'],
      
      // Thịt
      'thịt bò': ['Thịt bò hộp'],
      'thịt bò phở': ['Thịt bò hộp'],
      'thịt heo': ['Thịt lợn hộp'],
      'thịt lợn': ['Thịt lợn hộp'],
      'thịt gà': ['Thịt gà hộp'],
      'sườn': ['Sườn lợn'],
      'sườn nướng': ['Sườn lợn'],
      'sườn lợn': ['Sườn lợn'],
      'thịt vịt': ['Thịt vịt hầm'],
      'giò': ['Giò lụa'],
      'giò lụa': ['Giò lụa'],
      'chả': ['Chả quế'],
      'chả quế': ['Chả quế'],
      'chả giò': ['Chả giò'],
      'nem rán': ['Chả giò'],
      'nem': ['Chả giò'],
      'bì': ['Bì lợn'],
      'thịt nướng': ['Thịt lợn hộp'],

      // Hải sản
      'cá': ['Cá thu hộp'],
      'cá thu': ['Cá thu hộp'],
      'cá ngừ': ['Cá ngừ hộp'],
      'tôm': ['Tôm sú'],
      'mực': ['Mực tươi'],

      // Trứng & Đậu
      'trứng': ['Trứng gà ta'],
      'trứng gà': ['Trứng gà ta'],
      'trứng luộc': ['Trứng gà ta'],
      'trứng ốp la': ['Trứng gà ta'],
      'trứng chiên': ['Trứng gà ta'],
      'trứng vịt': ['Trứng vịt'],
      'đậu phụ': ['Đậu phụ sống'],
      'đậu hũ': ['Đậu phụ sống'],
      'tàu hũ': ['Đậu phụ sống'],

      // Rau
      'rau muống': ['Rau muống'],
      'rau thơm': ['Rau thơm'],
      'rau sống': ['Rau thơm'],
      'rau xà lách': ['Xà lách'],
      'xà lách': ['Xà lách'],
      'cà chua': ['Quả cà chua tươi'],
      'dưa leo': ['Dưa chuột'],
      'dưa chuột': ['Dưa chuột'],
      'hành lá': ['Hành lá'],
      'cải xanh': ['Cải xanh tươi'],
      'bắp cải': ['Bắp cải'],
      'cà rốt': ['Củ cà rốt tươi'],
      'khoai tây': ['Khoai tây tươi'],
      'khoai lang': ['Khoai lang tươi'],
      'bí đỏ': ['Quả bí ngô tươi'],
      'giá đỗ': ['Giá đỗ'],

      // Nước phở/canh
      'nước phở': ['Nước phở'],
      'nước canh': ['Nước canh'],
      'nước lèo': ['Nước phở'],
      'canh': ['Canh rau'],

      // Trái cây
      'chuối': ['Chuối tiêu tươi'],
      'táo': ['Táo ta tươi'],
      'cam': ['Cam tươi'],

      // Đồ uống
      'sữa': ['Sữa bò tươi'],
      'sữa tươi': ['Sữa bò tươi'],
      'sữa chua': ['Sữa chua'],
      'cà phê': ['Cà phê đá'],
      'trà': ['Trà'],
      'nước dừa': ['Nước dừa hộp'],
      'nước ngọt': ['Nước ngọt'],
    };

    // Tìm alias match
    for (var entry in ingredientAliases.entries) {
      if (lower == entry.key || lower.contains(entry.key) || entry.key.contains(lower)) {
        // Tìm trong DB theo danh sách tên ưu tiên
        for (var dbName in entry.value) {
          final found = _findByExactName(dbName);
          if (found != null) return found;
        }
      }
    }

    return null;
  }

  /// Tìm chính xác theo tên (không normalize)
  static FoodNutrition? _findByExactName(String exactName) {
    for (var food in FoodDatabaseGenerated.foods.values) {
      if (food.name == exactName) return food;
    }
    return null;
  }

  /// Lấy thông tin dinh dưỡng cho prompt (top foods)
static String getDatabaseSampleForPrompt() {
    final popularFoodKeys = [
      // Cơm & Tinh bột
      'com_trang', 'com_rang', 'xoi_nep_cam',
      // Phở & Bún
      'pho_bo_chin', 'pho_bo_tai', 'pho_ga',
      'bun_cha', 'bun_bo_nam_bo', 'bun_cua', 'bun_dau', 'bun_nem', 'bun_oc',
      // Bánh mì
      'banh_my_vuong_ngot', 'banh_my_xiu_mai',
      // Thịt
      'thit_lon_hop', 'thit_bo_hop', 'thit_ga_hop', 'thit_vit_ham',
      // Cá
      'ca_thu_hop', 'ca_trich_hop', 'ca_ngu_hop', 'ca_nuc_hop',
      // Trứng & Đậu
      'trung_ga_ta', 'dau_phu_song',
      // Rau củ
      'cai_xanh_tuoi', 'qua_ca_chua_tuoi', 'khoai_lang_tuoi', 'qua_bi_ngo_tuoi',
      'cu_ca_rot_tuoi', 'khoai_tay_tuoi',
      // Trái cây
      'chuoi_tieu_tuoi', 'tao_ta_tuoi', 'cam_tuoi',
      // Đồ uống
      'sua_bo_tuoi', 'sua_chua', 'ca_phe_da', 'tra', 'nuoc_dua_hop',
      'nuoc_ngot',
      // Snacks
      'banh_bong_lan', 'banh_bich_quy', 'banh_cha', 'keo_so_co_la',
    ];

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('📋 MÓN ĂN PHỔ BIẾN (${popularFoodKeys.length} món):');
    buffer.writeln('');

    int count = 0;
    for (var foodKey in popularFoodKeys) {
      final food = FoodDatabaseGenerated.foods[foodKey];
      if (food != null) {
        count++;
        // Hiển thị TÊN TIẾNG VIỆT để Gemini biết
        buffer.writeln('$count. ${food.name}');
      }
    }

    buffer.writeln('');
    buffer.writeln(
        '📊 Database tổng: ${FoodDatabaseGenerated.foods.length}+ món');
    buffer.writeln('');
    buffer
        .writeln('💡 CHỈ DẪN: Sử dụng CHÍNH XÁC tên món trong danh sách trên!');
    buffer.writeln('   Ví dụ: "Cơm trắng", "Phở bò", "Bún chả", "Trứng gà"...');

    return buffer.toString();
  }

  /// Enrich food item với data từ database
  static Map<String, dynamic> enrichFoodData(
    String name,
    double weight,
  ) {
    final foodData = findFood(name);

    if (foodData != null) {
      // Tính toán calories theo khối lượng thực tế
      final calories = (foodData.caloriesPer100g * weight / 100);

      // LƯU Ý: protein, carbs, fat, fiber lưu giá trị /100g (KHÔNG nhân weight)
      // actualProtein getter sẽ tính theo weight sau
      return {
        'name': foodData.name,
        'nameEn': foodData.nameEn,
        'weight': weight,
        'calories': calories,
        'protein': foodData.protein, // g/100g
        'carbs': foodData.carbs, // g/100g
        'fat': foodData.fat, // g/100g
        'fiber': foodData.fiber, // g/100g
        'glycemicIndex': foodData.glycemicIndex,
        'category': foodData.category,
        'source': 'database', // Đánh dấu từ database
      };
    }

    // Nếu không tìm thấy trong database, trả về data cơ bản
    return {
      'name': name,
      'weight': weight,
      'source': 'ai', // Đánh dấu từ AI
    };
  }

  /// Lấy tất cả categories
  static List<String> getAllCategories() {
    final categories = <String>{};
    for (var food in FoodDatabaseGenerated.foods.values) {
      categories.add(food.category);
    }
    return categories.toList()..sort();
  }

  /// Tìm món ăn theo category
  static List<FoodNutrition> getFoodsByCategory(String category) {
    return FoodDatabaseGenerated.foods.values
        .where((food) => food.category == category)
        .toList();
  }

  /// Search món ăn theo keyword
  static List<FoodNutrition> searchFoods(String keyword) {
    final normalizedKeyword = keyword.toLowerCase().trim();

    return FoodDatabaseGenerated.foods.values
        .where((food) =>
            food.name.toLowerCase().contains(normalizedKeyword) ||
            food.nameEn.toLowerCase().contains(normalizedKeyword))
        .toList();
  }

  /// Lấy FULL LIST tất cả món ăn trong database (dùng cho prompt)
  /// Returns: Danh sách đầy đủ 1,275 món theo category
  static String getCompleteDatabaseList() {
    final buffer = StringBuffer();

    // Group foods by category
    final categories = <String, List<FoodNutrition>>{};
    for (var food in FoodDatabaseGenerated.foods.values) {
      if (!categories.containsKey(food.category)) {
        categories[food.category] = [];
      }
      categories[food.category]!.add(food);
    }

    // Sort categories
    final sortedCategories = categories.keys.toList()..sort();

    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln(
        '📚 DATABASE: ${FoodDatabaseGenerated.foods.length} MÓN ĂN VIỆT NAM');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('');

    int totalCount = 0;
    for (var category in sortedCategories) {
      final foods = categories[category]!;
      buffer.writeln('📂 $category (${foods.length} món):');

      // Sort foods by name
      foods.sort((a, b) => a.name.compareTo(b.name));

      // List ALL foods with index
      for (var i = 0; i < foods.length; i++) {
        final food = foods[i];
        buffer.writeln('   ${i + 1}. ${food.name}');
        totalCount++;
      }
      buffer.writeln('');
    }

    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('📊 TỔNG CỘNG: $totalCount món (CHÍNH XÁC 100%)');
    buffer.writeln('═══════════════════════════════════════════════════════');

    return buffer.toString();
  }

  /// Get common aliases for better matching
  static Map<String, List<String>> getFoodAliases() {
    return {
      'cơm trắng': ['cơm', 'gạo trắng', 'com trang'],
      'phở bò': ['phở', 'phở tái', 'phở chín', 'pho bo'],
      'bún bò huế': ['bún bò', 'bún huế', 'bun bo hue'],
      'bánh mì': ['bánh mỳ', 'banh mi', 'banh my'],
      'trứng gà': ['trứng', 'trung ga'],
      'thịt lợn': ['thịt heo', 'thit lon', 'thit heo'],
      'thịt bò': ['bò', 'thit bo'],
      'cá rô phi': ['cá', 'ca ro phi'],
      'tôm sú': ['tôm', 'tom su', 'tom'],
      'rau muống': ['rau muống xào', 'rau muong'],
      'cà chua': ['ca chua', 'tomato'],
      'khoai tây': ['khoai tay', 'potato', 'khoai'],
      'sữa bò tươi': ['sữa', 'sua bo', 'sua'],
    };
  }
}
