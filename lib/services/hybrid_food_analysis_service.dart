import 'dart:io';
import 'package:monitor_food_intake/models/food_analysis.dart';
import 'package:monitor_food_intake/models/food_item.dart';
import 'package:monitor_food_intake/models/dish.dart';
import 'package:monitor_food_intake/services/gemini_service.dart';
import 'package:monitor_food_intake/services/semantic_food_search_service.dart';
import 'package:monitor_food_intake/services/yolo_detection_service.dart';
import 'package:monitor_food_intake/core/di/injection.dart';
import 'package:monitor_food_intake/services/local_food_classifier_service.dart';
import 'package:monitor_food_intake/services/food_label_mapper.dart';

/// Service KẾT HỢP YOLOv8 + EfficientNet (Offline) + Gemini AI (Online) + Database
class HybridFoodAnalysisService {
  late final GeminiService _geminiService;
  late final YoloDetectionService _yoloService;
  late final LocalFoodClassifierService _localClassifier;

  HybridFoodAnalysisService({String? apiKey}) {
    if (apiKey != null) {
      _geminiService = GeminiService(apiKey: apiKey);
    } else {
      // Try to get from DI container
      try {
        _geminiService = getIt<GeminiService>();
      } catch (e) {
        throw Exception(
            'GeminiService not found. Please provide apiKey or register GeminiService in DI.');
      }
    }

    // Initialize YOLO service
    _yoloService = YoloDetectionService();

    // Initialize Local Classifier
    try {
      _localClassifier = getIt<LocalFoodClassifierService>();
    } catch (e) {
      _localClassifier = LocalFoodClassifierService();
    }
  }

  /// Initialize AI models
  Future<void> initialize() async {
    await _yoloService.initialize();
    await _localClassifier.initialize();
  }

  /// Phân tích ảnh món ăn với HYBRID approach (Offline First)
  Future<FoodAnalysis> analyzeWithDatabase(
    File imageFile, {
    bool useSemanticSearch = true,
    bool tryOfflineFirst = true,
  }) async {
    print('🔍 [HYBRID] Starting hybrid analysis...');

    // 1. Thử Offline Mode trước (Nhanh & Free)
    if (tryOfflineFirst) {
      try {
        final offlineResult = await _analyzeOffline(imageFile);
        if (offlineResult != null && offlineResult.foods.isNotEmpty) {
          print('✅ [OFFLINE] Analysis successful using YOLO + EfficientNet');
          return offlineResult;
        }
      } catch (e) {
        print('⚠️ [OFFLINE] Failed, falling back to Gemini: $e');
      }
    }

    // 2. Fallback: Gemini AI nhận diện món ăn (Online)
    print('🤖 [GEMINI] Analyzing image with Gemini AI (Online)...');
    final geminiAnalysis = await _geminiService.analyzeFoodImage(imageFile);

    // Kiểm tra cả dishes và foods
    final hasDishes =
        geminiAnalysis.dishes != null && geminiAnalysis.dishes!.isNotEmpty;
    final hasFoods = geminiAnalysis.foods.isNotEmpty;

    if (!hasDishes && !hasFoods) {
      print('❌ [GEMINI] No food detected');
      return geminiAnalysis;
    }

    if (hasDishes) {
      print(
          '✅ [GEMINI] Detected ${geminiAnalysis.dishes!.length} dish(es) with ingredients');
    }
    if (hasFoods) {
      print(
          '✅ [GEMINI] Detected ${geminiAnalysis.foods.length} individual food(s)');
    }

    // 3. Enhance với database (hỗ trợ cả dishes và foods)
    if (useSemanticSearch) {
      print('🔍 [DATABASE] Enhancing with semantic search...');
      return _enhanceWithSemanticSearch(geminiAnalysis);
    } else {
      return geminiAnalysis;
    }
  }

  /// Phân tích Offline: YOLO -> Crop -> EfficientNet -> Mapper
  Future<FoodAnalysis?> _analyzeOffline(File imageFile) async {
    print('⚡ [OFFLINE] Attempting local analysis...');

    // Step 1: Detect objects with YOLO
    final detections = await _yoloService.detectObjects(imageFile);
    if (detections.isEmpty) {
      print('   ⚠️ YOLO found no objects');
      return null;
    }

    final detectedFoods = <FoodItem>[];

    // Step 2: Process each detection
    for (final detection in detections) {
      // Crop image
      final croppedFile =
          await _yoloService.cropImage(imageFile, detection.bbox);

      // Classify with EfficientNet
      final predictions = await _localClassifier.classify(croppedFile);
      if (predictions.isEmpty) continue;

      final topResult = predictions.first;
      print(
          '   🧩 Detected: ${topResult.label} (${(topResult.confidence * 100).toStringAsFixed(1)}%)');

      // Check confidence threshold (>60%)
      if (topResult.confidence < 0.6) {
        print('      -> Low confidence, skipping');
        continue;
      }

      // Map to Vietnamese Name
      final vietName = FoodLabelMapper.getVietnameseName(topResult.label);
      if (vietName == null) {
        print('      -> No Vietnamese mapping for "${topResult.label}"');
        continue;
      }

      // Search in Database to get nutrition
      final searchResult = SemanticFoodSearchService.searchBest(vietName);
      if (searchResult != null) {
        print('✅ Mapped to DB: "${searchResult.matchedName}"');

        double estimatedWeight = 200.0;

        final dbFood = searchResult.food;
        final foodItem = FoodItem(
          name: searchResult.matchedName,
          nameEn: dbFood.nameEn,
          weight: estimatedWeight,
          calories: (dbFood.caloriesPer100g * estimatedWeight / 100),
          protein: (dbFood.protein * estimatedWeight / 100),
          carbs: (dbFood.carbs * estimatedWeight / 100),
          fat: (dbFood.fat * estimatedWeight / 100),
          fiber: (dbFood.fiber * estimatedWeight / 100),
          glycemicIndex: dbFood.glycemicIndex?.toDouble(),
          category: dbFood.category,
        );

        detectedFoods.add(foodItem);
      }
    }

    if (detectedFoods.isNotEmpty) {
      return FoodAnalysis(
        foods: detectedFoods,
        timestamp: DateTime.now(),
        imagePath: imageFile.path,
      );
    }

    return null;
  }

  /// Tìm món ăn tốt nhất với multiple attempts
  /// Thử các biến thể của tên món để tăng độ chính xác
  FoodSearchResult? _findBestMatch(String foodName) {
    // Attempt 1: Tìm trực tiếp
    var result = SemanticFoodSearchService.searchBest(foodName);
    if (result != null && result.similarity >= _matchThreshold) {
      return result;
    }

    // Attempt 2: Loại bỏ các từ phụ và thử lại
    final cleanedName = _cleanFoodName(foodName);
    if (cleanedName != foodName) {
      result = SemanticFoodSearchService.searchBest(cleanedName);
      if (result != null && result.similarity >= _matchThreshold) {
        return result;
      }
    }

    // Attempt 3: Thử với từng từ chính
    final keywords = _extractKeywords(foodName);
    for (final keyword in keywords) {
      result = SemanticFoodSearchService.searchBest(keyword);
      if (result != null && result.similarity >= 0.6) {
        // Higher threshold for single keyword
        return result;
      }
    }

    // Trả về kết quả tốt nhất (có thể null hoặc dưới threshold)
    return SemanticFoodSearchService.searchBest(foodName);
  }

  /// Làm sạch tên món ăn - loại bỏ các từ phụ
  String _cleanFoodName(String name) {
    // Loại bỏ các từ không cần thiết
    const removeWords = [
      'tươi',
      'ngon',
      'nóng',
      'lạnh',
      'chín',
      'sống',
      'nhỏ',
      'vừa',
      'lớn',
      'to',
      'bé',
      'miếng',
      'lát',
      'khúc',
      'con',
      'quả',
      'cái',
      'bát',
      'đĩa',
      'tô',
      'đặc biệt',
      'thượng hạng',
      'cao cấp',
      'hà nội',
      'sài gòn',
      'huế',
      'nam',
      'bắc',
      'trung',
    ];

    String result = name.toLowerCase();
    for (final word in removeWords) {
      result =
          result.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Trích xuất từ khóa chính từ tên món
  List<String> _extractKeywords(String name) {
    const importantWords = [
      'cơm',
      'phở',
      'bún',
      'mì',
      'bánh',
      'xôi',
      'cháo',
      'thịt',
      'cá',
      'gà',
      'heo',
      'bò',
      'tôm',
      'trứng',
      'đậu',
      'rau',
      'canh',
      'gỏi',
      'chả',
      'nem',
      'xào',
      'kho',
      'nướng',
      'chiên',
      'luộc',
      'sườn',
      'đùi',
      'cánh',
      'tim',
      'gan',
    ];

    final words = name.toLowerCase().split(' ');
    final keywords = <String>[];

    for (final word in words) {
      if (importantWords.any((kw) => word.contains(kw))) {
        keywords.add(word);
      }
    }

    return keywords;
  }

  /// Enhance bằng SEMANTIC SEARCH (khuyến nghị) - Hỗ trợ cả dishes và foods
  /// Threshold: 0.4 (sau khi upgrade algorithm với N-gram + Levenshtein)
  static const double _matchThreshold = 0.4;

  FoodAnalysis _enhanceWithSemanticSearch(FoodAnalysis geminiAnalysis) {
    // 1. ENHANCE DISHES (nếu có)
    List<Dish>? enhancedDishes;
    if (geminiAnalysis.dishes != null && geminiAnalysis.dishes!.isNotEmpty) {
      enhancedDishes = [];
      int dishEnhancedCount = 0;

      for (final dish in geminiAnalysis.dishes!) {
        print('\n🍜 Processing Dish: "${dish.dishName}"');

        final enhancedIngredients = <FoodItem>[];
        int ingredientEnhancedCount = 0;

        for (final ingredient in dish.ingredients) {
          print('   📝 Ingredient: "${ingredient.name}"');

          // Tìm kiếm với multiple attempts
          final searchResult = _findBestMatch(ingredient.name);

          if (searchResult != null &&
              searchResult.similarity >= _matchThreshold) {
            print(
                '      ✅ Found in DB: "${searchResult.matchedName}" (${(searchResult.similarity * 100).toStringAsFixed(1)}%)');

            final weight = ingredient.weight;
            final dbFood = searchResult.food;

            enhancedIngredients.add(FoodItem(
              name: searchResult.matchedName,
              nameEn: dbFood.nameEn,
              weight: weight,
              calories: (dbFood.caloriesPer100g * weight / 100),
              protein: (dbFood.protein * weight / 100),
              carbs: (dbFood.carbs * weight / 100),
              fat: (dbFood.fat * weight / 100),
              fiber: (dbFood.fiber * weight / 100),
              glycemicIndex: dbFood.glycemicIndex?.toDouble(),
              category: dbFood.category,
            ));
            ingredientEnhancedCount++;
          } else {
            print('      ⚠️ Not found in DB (keep original)');
            enhancedIngredients.add(ingredient);
          }
        }

        enhancedDishes.add(Dish(
          dishName: dish.dishName,
          ingredients: enhancedIngredients,
        ));

        if (ingredientEnhancedCount > 0) {
          dishEnhancedCount++;
        }
        print(
            '   📊 Enhanced $ingredientEnhancedCount/${dish.ingredients.length} ingredients');
      }

      print(
          '\n🍽️ [DISHES] Enhanced $dishEnhancedCount/${geminiAnalysis.dishes!.length} dishes');
    }

    // 2. ENHANCE FOODS (legacy format)
    final enhancedFoods = <FoodItem>[];
    int enhancedCount = 0;

    for (final food in geminiAnalysis.foods) {
      print('\n📝 Processing Food: "${food.name}"');

      // Sử dụng _findBestMatch với multiple attempts
      final searchResult = _findBestMatch(food.name);

      if (searchResult != null && searchResult.similarity >= _matchThreshold) {
        print(
            '   ✅ Found in DB: "${searchResult.matchedName}" (${(searchResult.similarity * 100).toStringAsFixed(1)}%)');

        final weight = food.weight;
        final dbFood = searchResult.food;

        enhancedFoods.add(FoodItem(
          name: searchResult.matchedName,
          nameEn: dbFood.nameEn,
          weight: weight,
          calories: (dbFood.caloriesPer100g * weight / 100),
          protein: (dbFood.protein * weight / 100),
          carbs: (dbFood.carbs * weight / 100),
          fat: (dbFood.fat * weight / 100),
          fiber: (dbFood.fiber * weight / 100),
          glycemicIndex: dbFood.glycemicIndex?.toDouble(),
          category: dbFood.category,
        ));
        enhancedCount++;
      } else {
        print('   ⚠️ Not found in DB (keep Gemini result)');
        enhancedFoods.add(food);
      }
    }

    if (geminiAnalysis.foods.isNotEmpty) {
      print(
          '\n📊 [FOODS] Enhanced $enhancedCount/${geminiAnalysis.foods.length} foods from database');
    }

    return FoodAnalysis(
      foods: enhancedFoods,
      dishes: enhancedDishes,
      timestamp: geminiAnalysis.timestamp,
      imagePath: geminiAnalysis.imagePath,
    );
  }

  /// Test với ảnh mẫu
  // Future<void> testHybridAnalysis(File imageFile) async {
  //   print('\n🧪 TESTING HYBRID ANALYSIS\n');
  //   print('═══════════════════════════════════════════\n');

  //   try {
  //     final result = await analyzeWithDatabase(imageFile);

  //     print('\n📊 FINAL RESULTS:');
  //     print('═══════════════════════════════════════════');
  //     print('Foods detected: ${result.foods.length}\n');

  //     for (int i = 0; i < result.foods.length; i++) {
  //       final food = result.foods[i];
  //       print('${i + 1}. ${food.name}');
  //       print('   Weight: ${food.weight}g');
  //       print('   Calories: ${food.calories.toStringAsFixed(1)} kcal');
  //       print('');
  //     }

  //     print('═══════════════════════════════════════════');
  //     print('TOTAL CALORIES: ${result.totalCalories.toStringAsFixed(1)} kcal');
  //     print('═══════════════════════════════════════════\n');
  //   } catch (e) {
  //     print('❌ Error: $e');
  //   }
  // }
}
