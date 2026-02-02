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
        temperature: 0.2,
        topK: 32,
        topP: 1,
        maxOutputTokens: 3000,
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
      print('📝 Response preview: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...');

      // Parse JSON từ response
      final analysis = _parseGeminiResponse(responseText, imageFile.path);
      

      return analysis;
    } on FileSystemException catch (e) {

      throw Exception('Không thể đọc file ảnh: ${e.message}');
    } on FormatException {

      throw Exception('Gemini trả về JSON không hợp lệ');
    } on SocketException {

      throw Exception('Không có kết nối internet. Vui lòng kiểm tra mạng của bạn.');
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

      // LOẠI BỎ THÀNH PHẦN TRÙNG TÊN VỚI MÓN ĂN
      final dishNameLower = dishName.toLowerCase().trim();
      final ingredients = allIngredients.where((ingredient) {
        final ingredientNameLower = ingredient.name.toLowerCase().trim();

        // Loại bỏ nếu tên thành phần giống hệt tên món
        if (ingredientNameLower == dishNameLower) {
          return false;
        }

        // Loại bỏ nếu tên món chứa trong tên thành phần (VD: "Bún chả" vs "Bún chả Hà Nội")
        if (ingredientNameLower.contains(dishNameLower) &&
            ingredientNameLower.length - dishNameLower.length < 10) {
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
}
