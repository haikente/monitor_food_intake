import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:monitor_food_intake/models/food_analysis.dart';
import 'package:monitor_food_intake/models/food_item.dart';
import 'package:monitor_food_intake/services/gemini_service.dart';
import 'package:monitor_food_intake/services/yolo_detection_service.dart';
import 'package:monitor_food_intake/services/image_based_semantic_search_service.dart';
import 'package:monitor_food_intake/services/image_embedding_service.dart';
import 'package:monitor_food_intake/core/di/injection.dart';

class HybridImageBasedAnalysisService {
  late final GeminiService _geminiService;
  late final YoloDetectionService _yoloService;
  late final ImageEmbeddingService _embeddingService;
  late final ImageBasedSemanticSearchService _imageSearchService;

  HybridImageBasedAnalysisService({String? apiKey}) {
    if (apiKey != null) {
      _geminiService = GeminiService(apiKey: apiKey);
    } else {
      try {
        _geminiService = getIt<GeminiService>();
      } catch (e) {
        throw Exception(
            'GeminiService not found. Please provide apiKey or register GeminiService in DI.');
      }
    }

    _yoloService = YoloDetectionService();
    _embeddingService = ImageEmbeddingService();
    _imageSearchService = ImageBasedSemanticSearchService(_embeddingService);
  }

  /// Initialize YOLO + Embedding models
  Future<void> initialize({required String foodImagesDir}) async {
    print('🔧 Initializing Hybrid Image-Based Service...');

    // Initialize YOLO
    await _yoloService.initialize();

    // Initialize Embedding model
    await _embeddingService.initialize();

    // Initialize database embeddings (cache)
    await _imageSearchService.initializeDatabaseEmbeddings(
      foodImagesDir: foodImagesDir,
    );

    print('✅ Hybrid Image-Based Service ready!');
  }

  /// Phân tích ảnh với IMAGE-BASED approach
  Future<FoodAnalysis> analyzeWithImageSearch(File imageFile) async {
    print('🔍 [IMAGE-BASED] Starting analysis...');

    // 1. YOLO detection
    print('🎯 [YOLO] Detecting food regions...');
    final detections = await _yoloService.detectObjects(imageFile);

    if (detections.isEmpty) {
      print('❌ [YOLO] No food detected');
      return FoodAnalysis(
        foods: [],
        timestamp: DateTime.now(),
        imagePath: imageFile.path,
      );
    }

    print('✅ [YOLO] Detected ${detections.length} food region(s)');

    // 2. Crop images
    print('✂️ [CROP] Cropping food regions...');
    final croppedImages = <File>[];
    for (final detection in detections) {
      final croppedImage =
          await _yoloService.cropImage(imageFile, detection.bbox);
      croppedImages.add(croppedImage);
    }
    print('✅ [CROP] ${croppedImages.length} images cropped');

    // 3. IMAGE-BASED SEMANTIC SEARCH (thay vì Gemini recognition)
    print('🔍 [IMAGE SEARCH] Searching in database...');
    final searchResults = await _imageSearchService.searchMultipleByImages(
      croppedImages,
      minSimilarity: 0.6,
    );

    // 4. Weight estimation with Gemini (lightweight prompt)
    print('⚖️ [GEMINI] Estimating weights...');
    final foods = <FoodItem>[];

    for (int i = 0; i < searchResults.length; i++) {
      final searchResult = searchResults[i];
      final croppedImage = croppedImages[i];

      if (searchResult == null) {
     
        continue;
      }

      // Estimate weight using Gemini (simple prompt)
      final estimatedWeight =
          await _estimateWeight(croppedImage, searchResult.food.name);

      // Calculate nutrition
      final weight = estimatedWeight;
      final dbFood = searchResult.food;

      final foodItem = FoodItem(
        name: dbFood.name,
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

      foods.add(foodItem);
    }
    return FoodAnalysis(
      foods: foods,
      timestamp: DateTime.now(),
      imagePath: imageFile.path,
    );
  }

  Future<double> _estimateWeight(File croppedImage, String foodName) async {
    try {
      final prompt = '''
Ảnh này là món: $foodName

Hãy ước lượng KHỐI LƯỢNG (gram) của món ăn trong ảnh.

Trả về JSON:
{
  "weight": <số gram>
}

Ví dụ:
- 1 bát cơm: 150g
- 1 miếng thịt: 80g
- 1 bát canh: 200g
''';

      final imageBytes = await croppedImage.readAsBytes();

      // Call Gemini (simple text generation)
      final response = await _geminiService.model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final responseText = response.text;
      if (responseText == null) {
        return 100.0; // Default fallback
      }

      // Parse JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        return 100.0;
      }

      final jsonText = jsonMatch.group(0)!;
      final data = jsonText.contains('"weight"')
          ? double.tryParse(jsonText
                  .split('"weight"')[1]
                  .split(':')[1]
                  .split('}')[0]
                  .trim()) ??
              100.0
          : 100.0;

      return data;
    } catch (e) {
      return 100.0;
    }
  }

  /// Dispose resources
  void dispose() {
    _embeddingService.dispose();
  }
}
