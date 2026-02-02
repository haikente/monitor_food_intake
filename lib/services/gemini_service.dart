import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:monitor_food_intake/services/geminiprompts.dart';
import '../models/food_analysis.dart';
import '../models/food_item.dart';
import '../models/dish.dart';
import 'food_database_service.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel model;

  GeminiService({required this.apiKey}) {
    model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, 
        topK: 40, 
        topP: 0.95,
        maxOutputTokens:
            4096,
      ),
    );
  }

  /// Phân tích ảnh thực phẩm và trả về danh sách món ăn
  Future<FoodAnalysis> analyzeFoodImage(File imageFile) async {
  try {
      final imageBytes = await imageFile.readAsBytes();

      // Lấy prompt từ file riêng
      final prompt = GeminiPrompts.buildFoodAnalysisPrompt();

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Gọi API
      final response = await model.generateContent(content);

      // Lấy text từ response
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Gemini trả về kết quả rỗng');
      }

      // ignore: avoid_print
      print(
          '📝 Response preview: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...');

      // Parse JSON từ response
      final analysis = _parseGeminiResponse(responseText, imageFile.path);


      return analysis;
    } on FileSystemException catch (e) {

      throw Exception('Không thể đọc file ảnh: ${e.message}');
    } on FormatException {

      throw Exception('Gemini trả về JSON không hợp lệ');
    } on SocketException {
      throw Exception(
          'Không có kết nối internet. Vui lòng kiểm tra mạng của bạn.');
    } on GenerativeAIException catch (e) {


      // Xử lý các lỗi Gemini cụ thể
      final errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('api key') ||
          errorMessage.contains('api_key_invalid') ||
          errorMessage.contains('403') ||
          errorMessage.contains('401')) {
        throw Exception('API key không hợp lệ hoặc không có quyền.\n'
            'Vui lòng kiểm tra GEMINI_API_KEY trong file .env\n'
            'Lấy key mới tại: https://aistudio.google.com/app/apikey\n\n'
            'Chi tiết: $e');
      }

      if (errorMessage.contains('429') ||
          errorMessage.contains('quota') ||
          errorMessage.contains('rate limit')) {
        throw Exception('Đã vượt quota API hoặc rate limit.\n'
            'Vui lòng đợi hoặc tạo key mới.\n\n'
            'Chi tiết: $e');
      }

      if (errorMessage.contains('404') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('model')) {
        throw Exception('Model không khả dụng.\n'
            'Thử model khác hoặc kiểm tra API key.\n\n'
            'Chi tiết: $e');
      }

      throw Exception('Lỗi Gemini API: ${e.message}');
    } catch (e) {

      throw Exception('Lỗi khi phân tích ảnh: $e');
    }
  }

  /// Parse response từ Gemini
  FoodAnalysis _parseGeminiResponse(String responseText, String imagePath) {
    try {
      // Loại bỏ markdown code block nếu có
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON
      final Map<String, dynamic> jsonData = json.decode(jsonText);

      // Kiểm tra format: "dishes" hoặc "foods"
      final hasDishes = jsonData.containsKey('dishes');
      final hasFoods = jsonData.containsKey('foods');

      List<FoodItem> foods = [];
      List<Dish>? dishes;

      // XỬ LÝ FORMAT "DISHES" (món ăn + thành phần)
      if (hasDishes) {
        dishes = _parseDishes(jsonData['dishes'] as List);
      }

      // XỬ LÝ FORMAT "FOODS" (danh sách đơn giản)
      if (hasFoods) {
        final foodsJson = jsonData['foods'] as List;
        foods = _parseFoodsList(foodsJson);
      }

      // Trả về FoodAnalysis
      return FoodAnalysis(
        foods: foods,
        dishes: dishes,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    } catch (e) {
      throw Exception(
          'Không thể parse JSON từ Gemini: $e\n\nResponse: $responseText');
    }
  }

  /// Parse danh sách dishes (món ăn + thành phần)
  List<Dish> _parseDishes(List dishesJson) {
    final List<Dish> dishes = [];

    for (var i = 0; i < dishesJson.length; i++) {
      final dishJson = dishesJson[i];

      final dishName = dishJson['dishName'] as String;
      final ingredientsJson = dishJson['ingredients'] as List;

      final allIngredients = _parseFoodsList(ingredientsJson);

      // LOẠI BỎ THÀNH PHẦN TRÙNG TÊN VỚI MÓN ĂN (Improved fuzzy matching)
      final dishNameLower = _normalizeVietnamese(dishName.toLowerCase().trim());
      final ingredients = allIngredients.where((ingredient) {
        final ingredientNameLower =
            _normalizeVietnamese(ingredient.name.toLowerCase().trim());

        // Loại bỏ nếu tên thành phần giống hệt tên món
        if (ingredientNameLower == dishNameLower) {
          return false;
        }

        // Loại bỏ nếu tên món chứa trong tên thành phần
        if (ingredientNameLower.contains(dishNameLower) &&
            ingredientNameLower.length - dishNameLower.length < 10) {
          return false;
        }

        // Loại bỏ nếu similarity > 85% (Levenshtein distance)
        if (_calculateSimilarity(dishNameLower, ingredientNameLower) > 0.85) {
          return false;
        }

        return true;
      }).toList();

      if (ingredients.isEmpty) {
        dishes.add(Dish(
          dishName: dishName,
          ingredients: allIngredients,
        ));
      } else {
        dishes.add(Dish(
          dishName: dishName,
          ingredients: ingredients,
        ));
      }
    }
    return dishes;
  }

  /// Parse danh sách foods (legacy format hoặc ingredients)
  List<FoodItem> _parseFoodsList(List foodsJson) {
    final List<FoodItem> foods = [];

    for (var i = 0; i < foodsJson.length; i++) {
      final foodJson = foodsJson[i];

      final name = foodJson['name'] as String;
      final weight = (foodJson['weight'] as num).toDouble();

      // Kiểm tra xem AI có nhận diện được món ăn không
      if (name.toLowerCase() == 'unknown' ||
          name.toLowerCase().contains('không xác định') ||
          name.toLowerCase().contains('không rõ')) {

        // AI không nhận diện được → tạo món "Unknown" để user tự điền
        foods.add(FoodItem(
          name: 'Unknown',
          weight: weight,
          calories: 0,
          glycemicIndex: null,
          protein: null,
          carbs: null,
          fat: null,
          fiber: null,
          category: 'Chưa xác định',
          nameEn: 'Unknown food - please edit',
        ));
        continue;
      }

      // Kiểm tra xem Gemini có tự phân tích không (có calories field)
      final hasCaloriesField = foodJson.containsKey('calories');

      if (hasCaloriesField) {
        // CASE 2: Món KHÔNG trong DB, Gemini đã tự phân tích

        final calories = (foodJson['calories'] as num?)?.toDouble() ?? 0;
        final protein = (foodJson['protein'] as num?)?.toDouble();
        final carbs = (foodJson['carbs'] as num?)?.toDouble();
        final fat = (foodJson['fat'] as num?)?.toDouble();
        final fiber = (foodJson['fiber'] as num?)?.toDouble();
        final gi = (foodJson['glycemicIndex'] as num?)?.toDouble();

        // Tính calories thực tế dựa trên khối lượng
        final actualCalories = calories * weight / 100;

        foods.add(FoodItem(
          name: name,
          weight: weight,
          calories: actualCalories,
          glycemicIndex: gi,
          protein: protein, // per 100g
          carbs: carbs, // per 100g
          fat: fat, // per 100g
          fiber: fiber, // per 100g
          category: 'Tự phân tích bởi AI',
          nameEn: name,
        ));
      } else {
        // CASE 1: Món có thể trong DB, tra cứu
        final enrichedData = FoodDatabaseService.enrichFoodData(name, weight);
        if (enrichedData['source'] == 'database') {
          foods.add(FoodItem(
            name: enrichedData['name'],
            weight: enrichedData['weight'],
            calories: enrichedData['calories'],
            glycemicIndex: enrichedData['glycemicIndex'],
            protein: enrichedData['protein'], // /100g
            carbs: enrichedData['carbs'], // /100g
            fat: enrichedData['fat'], // /100g
            fiber: enrichedData['fiber'], // /100g
            category: enrichedData['category'],
            nameEn: enrichedData['nameEn'],
          ));
        } else {
          foods.add(FoodItem(
            name: 'Unknown ($name)',
            weight: weight,
            calories: 0,
            glycemicIndex: null,
            protein: null,
            carbs: null,
            fat: null,
            fiber: null,
            category: 'Chưa xác định',
            nameEn: 'Unknown food - please edit',
          ));
        }
      }
    }
    return foods;
  }

  /// Normalize Vietnamese text để so sánh chính xác hơn
  String _normalizeVietnamese(String text) {
    // Loại bỏ dấu tiếng Việt để so sánh
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

    String normalized = text;
    vietnameseMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Loại bỏ khoảng trắng thừa
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Tính độ tương đồng giữa 2 chuỗi (Levenshtein distance)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final len1 = s1.length;
    final len2 = s2.length;

    // Matrix cho dynamic programming
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize
    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculate Levenshtein distance
    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final distance = matrix[len1][len2];
    final maxLen = len1 > len2 ? len1 : len2;

    // Similarity = 1 - (distance / maxLength)
    return 1.0 - (distance / maxLen);
  }

}
