import 'dart:io';
import 'package:monitor_food_intake/models/food_analysis.dart';
import 'package:monitor_food_intake/models/food_item.dart';
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

    if (geminiAnalysis.foods.isEmpty) {
      print('❌ [GEMINI] No food detected');
      return geminiAnalysis;
    }

    print('✅ [GEMINI] Detected ${geminiAnalysis.foods.length} food(s)');

    // 3. Enhance với database
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

  /// Enhance bằng SEMANTIC SEARCH (khuyến nghị)
  FoodAnalysis _enhanceWithSemanticSearch(FoodAnalysis geminiAnalysis) {
    final enhancedFoods = <FoodItem>[];
    int enhancedCount = 0;

    for (final food in geminiAnalysis.foods) {
      print('\n📝 Processing: "${food.name}"');

      // Tìm kiếm semantic
      final searchResult = SemanticFoodSearchService.searchBest(food.name);

      if (searchResult != null && searchResult.similarity >= 0.5) {
        // Tìm thấy món trong database
        print(
            '   ✅ Found in DB: "${searchResult.matchedName}" (${(searchResult.similarity * 100).toStringAsFixed(1)}%)');

        // Tính nutrition dựa trên weight từ Gemini
        final weight = food.weight;
        final dbFood = searchResult.food;

        final enhancedFood = FoodItem(
          name: searchResult.matchedName, // Dùng tên chính xác từ DB
          nameEn: dbFood.nameEn,
          weight: weight,
          calories: (dbFood.caloriesPer100g * weight / 100),
          protein: (dbFood.protein * weight / 100),
          carbs: (dbFood.carbs * weight / 100),
          fat: (dbFood.fat * weight / 100),
          fiber: (dbFood.fiber * weight / 100),
          glycemicIndex: dbFood.glycemicIndex?.toDouble(),
          category: dbFood.category,
        );

        enhancedFoods.add(enhancedFood);
        enhancedCount++;
      } else {
        // Không tìm thấy trong DB → Giữ nguyên Gemini result
        print('   ⚠️ Not found in DB (keep Gemini result)');
        enhancedFoods.add(food);
      }
    }

    print(
        '\n📊 [RESULT] Enhanced ${enhancedCount}/${geminiAnalysis.foods.length} foods from database');

    return FoodAnalysis(
      foods: enhancedFoods,
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
