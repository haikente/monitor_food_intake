import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:monitor_food_intake/services/geminiprompts.dart';
import '../models/food_analysis.dart';
import '../models/food_item.dart';
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
      print('📸 Đang đọc ảnh...');

      // Đọc file ảnh
      final imageBytes = await imageFile.readAsBytes();
      print('✅ Đã đọc ảnh: ${imageBytes.length} bytes');

      // Lấy prompt từ file riêng
      final prompt = GeminiPrompts.buildFoodAnalysisPrompt();
      print('✅ Đã tạo prompt');

      // Tạo content với ảnh và text
      print('🚀 Đang gọi Gemini API...');

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Gọi API
      final response = await model.generateContent(content);

      print('✅ Nhận được response từ Gemini');

      // Lấy text từ response
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Gemini trả về kết quả rỗng');
      }

      print(
          '📝 Response preview: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...');

      // Parse JSON từ response
      final analysis = _parseGeminiResponse(responseText, imageFile.path);

      print('✅ Parse thành công: ${analysis.foods.length} món ăn');

      return analysis;
    } on FileSystemException catch (e) {
      print('❌ Lỗi đọc file: $e');
      throw Exception('Không thể đọc file ảnh: ${e.message}');
    } on FormatException catch (e) {
      print('❌ Lỗi format JSON: $e');
      throw Exception('Gemini trả về JSON không hợp lệ');
    } on SocketException catch (e) {
      print('❌ Lỗi network: $e');
      throw Exception(
          'Không có kết nối internet. Vui lòng kiểm tra mạng của bạn.');
    } on GenerativeAIException catch (e) {
      print('❌ Lỗi Gemini API: $e');

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
      print('❌ Lỗi: $e');
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

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 GEMINI RESPONSE:');
      print(jsonText);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Tạo danh sách FoodItem
      final List<FoodItem> foods = [];
      final foodsJson = jsonData['foods'] as List;

      print('\n🔍 PROCESSING ${foodsJson.length} FOODS:');

      for (var i = 0; i < foodsJson.length; i++) {
        final foodJson = foodsJson[i];
        print('\n📦 Food #${i + 1}:');

        final name = foodJson['name'] as String;
        final weight = (foodJson['weight'] as num).toDouble();

        print('   - Name: "$name"');
        print('   - Weight: ${weight}g');

        // Kiểm tra xem AI có nhận diện được món ăn không
        if (name.toLowerCase() == 'unknown' ||
            name.toLowerCase().contains('không xác định') ||
            name.toLowerCase().contains('không rõ')) {
          // AI không nhận diện được → tạo món "Unknown" để user tự điền
          print('   ⚠️ Marked as Unknown - requires manual input');
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
          print('   🤖 AI ANALYZED (not in database)');

          final calories = (foodJson['calories'] as num?)?.toDouble() ?? 0;
          final protein = (foodJson['protein'] as num?)?.toDouble();
          final carbs = (foodJson['carbs'] as num?)?.toDouble();
          final fat = (foodJson['fat'] as num?)?.toDouble();
          final fiber = (foodJson['fiber'] as num?)?.toDouble();
          final gi = (foodJson['glycemicIndex'] as num?)?.toDouble();

          print('      → Calories: $calories kcal');
          print('      → Protein: ${protein ?? 0}g');
          print('      → Carbs: ${carbs ?? 0}g');
          print('      → Fat: ${fat ?? 0}g');

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
          print('   🔎 Looking up in database...');
          final enrichedData = FoodDatabaseService.enrichFoodData(name, weight);

          if (enrichedData['source'] == 'database') {
            // Tìm thấy trong database → dùng 100% data từ database
            print('   ✅ DATABASE FOUND!');
            print('      → Matched: "${enrichedData['name']}"');
            print('      → Category: ${enrichedData['category']}');
            print('      → Calories: ${enrichedData['calories']} kcal');

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
            // KHÔNG tìm thấy trong database VÀ AI không tự phân tích
            print('   ❌ NOT FOUND IN DATABASE');
            print('      → Creating Unknown entry');

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

      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ FINAL RESULT: ${foods.length} foods processed');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      // Trả về FoodAnalysis
      return FoodAnalysis(
        foods: foods,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );
    } catch (e) {
      throw Exception(
          'Không thể parse JSON từ Gemini: $e\n\nResponse: $responseText');
    }
  }
}
