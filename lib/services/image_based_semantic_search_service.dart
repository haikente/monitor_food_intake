import 'dart:io';
import 'package:monitor_food_intake/data/database/food_database_generated.dart';
import 'package:monitor_food_intake/models/food_nutrition.dart';
import 'package:monitor_food_intake/services/image_embedding_service.dart';

/// Service tìm kiếm món ăn dựa trên IMAGE-BASED SEMANTIC SEARCH
///
/// Workflow:
/// 1. Generate embedding vector từ ảnh input [512D]
/// 2. So sánh với embeddings của 1,275 món trong database
/// 3. Tính cosine similarity
/// 4. Trả về món có similarity cao nhất
///
/// Advantages over TEXT-based:
/// ✅ Không phụ thuộc vào Gemini AI nhận diện tên món
/// ✅ Tìm trực tiếp từ visual features
/// ✅ Chính xác hơn cho món "khó nhận diện tên"
/// ✅ Hoạt động với món ăn mới (không có trong Gemini training data)
class ImageBasedSemanticSearchService {
  final ImageEmbeddingService _embeddingService;

  // Cache embeddings của database (để không phải tính lại mỗi lần)
  static Map<String, List<double>>? _databaseEmbeddings;
  static bool _isEmbeddingsCached = false;

  ImageBasedSemanticSearchService(this._embeddingService);

  /// Initialize: Generate embeddings cho TẤT CẢ món trong database
  ///
  /// ⚠️ Warning: Tốn thời gian (~10-15 phút cho 1,275 món)
  /// → Chỉ chạy 1 lần, sau đó cache lại
  Future<void> initializeDatabaseEmbeddings({
    required String foodImagesDir,
  }) async {
    if (_isEmbeddingsCached) {
      print('✅ Database embeddings already cached');
      return;
    }

    print('🧠 Generating embeddings for 1,275 foods...');
    print('⏱️ This may take 10-15 minutes...');

    _databaseEmbeddings = {};

    int processed = 0;
    final total = FoodDatabaseGenerated.foods.length;

    for (final entry in FoodDatabaseGenerated.foods.entries) {
      final foodKey = entry.key;

      try {
        // Tìm ảnh tương ứng với món ăn
        // VD: "com_trang" → "com_trang.jpg"
        final imagePath = '$foodImagesDir/$foodKey.jpg';
        final imageFile = File(imagePath);

        if (!imageFile.existsSync()) {
          print('⚠️ Image not found: $imagePath');
          continue;
        }

        // Generate embedding
        final embedding = await _embeddingService.generateEmbedding(imageFile);
        _databaseEmbeddings![foodKey] = embedding;

        processed++;
        if (processed % 50 == 0) {
          print(
              '   Progress: $processed/$total (${(processed / total * 100).toStringAsFixed(1)}%)');
        }
      } catch (e) {
        print('❌ Error processing $foodKey: $e');
      }
    }

    _isEmbeddingsCached = true;
    print(
        '✅ Database embeddings generated: ${_databaseEmbeddings!.length} foods');
  }

  /// Search món ăn từ IMAGE (không cần tên món)
  ///
  /// Input: File ảnh món ăn
  /// Output: Top N món giống nhất dựa trên visual similarity
  Future<List<ImageSearchResult>> searchByImage(
    File imageFile, {
    int topN = 5,
    double minSimilarity = 0.5,
  }) async {
    if (_databaseEmbeddings == null || _databaseEmbeddings!.isEmpty) {
      throw Exception(
          'Database embeddings not initialized. Call initializeDatabaseEmbeddings() first.');
    }

    // 1. Generate embedding cho ảnh input
    print('🔍 Generating embedding for query image...');
    final queryEmbedding = await _embeddingService.generateEmbedding(imageFile);

    // 2. Tính similarity với tất cả món trong database
    print(
        '🔍 Comparing with ${_databaseEmbeddings!.length} foods in database...');
    final results = <ImageSearchResult>[];

    for (final entry in _databaseEmbeddings!.entries) {
      final foodKey = entry.key;
      final dbEmbedding = entry.value;

      // Cosine similarity (dot product vì đã L2 normalized)
      final similarity = ImageEmbeddingService.cosineSimilarity(
        queryEmbedding,
        dbEmbedding,
      );

      // Chỉ lấy món có similarity >= threshold
      if (similarity >= minSimilarity) {
        final food = FoodDatabaseGenerated.foods[foodKey];
        if (food != null) {
          results.add(ImageSearchResult(
            food: food,
            similarity: similarity,
            foodKey: foodKey,
          ));
        }
      }
    }

    // 3. Sort theo similarity giảm dần
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    // 4. Trả về top N
    final topResults = results.take(topN).toList();

    print('✅ Found ${topResults.length} matches');
    for (int i = 0; i < topResults.length; i++) {
      final result = topResults[i];
      print(
          '   ${i + 1}. ${result.food.name} (${(result.similarity * 100).toStringAsFixed(1)}%)');
    }

    return topResults;
  }

  /// Search món CHÍNH XÁC NHẤT (top 1)
  Future<ImageSearchResult?> searchBestByImage(File imageFile) async {
    final results = await searchByImage(imageFile, topN: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Search nhiều món từ YOLO crops
  ///
  /// Input: List các ảnh đã crop từ YOLO
  /// Output: List món ăn tương ứng với mỗi crop
  Future<List<ImageSearchResult?>> searchMultipleByImages(
    List<File> cropFiles, {
    double minSimilarity = 0.5,
  }) async {
    final results = <ImageSearchResult?>[];

    for (final cropFile in cropFiles) {
      final result = await searchBestByImage(cropFile);

      // Chỉ thêm nếu similarity đủ cao
      if (result != null && result.similarity >= minSimilarity) {
        results.add(result);
      } else {
        results.add(null); // Không tìm thấy match tốt
      }
    }

    return results;
  }

  /// Load cached embeddings từ file (nếu đã generate trước đó)
  ///
  /// TODO: Implement save/load embeddings to avoid regenerating
  Future<void> loadCachedEmbeddings(String cachePath) async {
    // TODO: Implement JSON/binary file cache
    throw UnimplementedError('Cache loading not implemented yet');
  }

  /// Save embeddings to cache file
  Future<void> saveCachedEmbeddings(String cachePath) async {
    // TODO: Implement JSON/binary file cache
    throw UnimplementedError('Cache saving not implemented yet');
  }
}

/// Kết quả tìm kiếm image-based
class ImageSearchResult {
  final FoodNutrition food;
  final double similarity; // -1.0 → 1.0 (cosine similarity)
  final String foodKey;

  ImageSearchResult({
    required this.food,
    required this.similarity,
    required this.foodKey,
  });

  /// Có phải match tốt không? (>= 70%)
  bool get isGoodMatch => similarity >= 0.7;

  /// Match tuyệt vời? (>= 90%)
  bool get isExcellentMatch => similarity >= 0.9;

  /// Convert similarity to percentage
  String get similarityPercentage =>
      '${(similarity * 100).toStringAsFixed(1)}%';
}
