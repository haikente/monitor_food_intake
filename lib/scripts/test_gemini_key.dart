import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Test script đơn giản để kiểm tra Gemini API key
void main() async {
  print('🔍 KIỂM TRA GEMINI API KEY');
  print('=' * 50);
  print('');

  // Đọc API key từ file .env
  final envFile = File('.env');

  if (!await envFile.exists()) {
    print('❌ Không tìm thấy file .env');
    print('📝 Vui lòng tạo file .env với nội dung:');
    print('   GEMINI_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxx');
    return;
  }

  final envContent = await envFile.readAsString();
  final lines = envContent.split('\n');
  String apiKey = '';

  for (var line in lines) {
    if (line.trim().startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_KEY_HERE') {
    print('❌ Không tìm thấy GEMINI_API_KEY hợp lệ trong file .env');
    print('');
    print('📝 Hiện tại file .env có:');
    print(envContent);
    print('');
    print('🔑 Cách lấy API key:');
    print('   1. Vào: https://aistudio.google.com/app/apikey');
    print('   2. Đăng nhập Google account');
    print('   3. Click "Create API Key"');
    print('   4. Copy key (bắt đầu bằng AIza...)');
    print('   5. Dán vào file .env:');
    print('      GEMINI_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxx');
    return;
  }

  print('✅ Tìm thấy API key: ${apiKey.substring(0, 20)}...');
  print('');

  // Test với các models khác nhau (v1 API với models/ prefix)
  final modelsToTest = [
    'models/gemini-1.5-flash-latest',
    'models/gemini-1.5-pro-latest',
    'models/gemini-pro-vision',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro-latest',
    'gemini-pro-vision',
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash-tts',
    'gemini-3-flash',
    'gemini-robotics-er-1.5-preview',
    'gemini-2.5-flash'
  ];

  for (var modelName in modelsToTest) {
    print('🚀 Test model: $modelName');
    print('-' * 50);

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

      print('   Đang gọi API...');

      final content = [Content.text('Say "Xin chào" in English')];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText != null && responseText.isNotEmpty) {
        print('   ✅ SUCCESS!');
        print('   📝 Response: $responseText');
        print('');

        // Nếu model này OK, dùng nó!
        print('🎉 MODEL HOẠT ĐỘNG: $modelName');
        print('');
        print('💡 Cập nhật code để dùng model này:');
        print('   model: GenerativeModel(');
        print('     model: \'$modelName\',');
        print('     apiKey: apiKey,');
        print('   );');
        print('');
        print('✅ App sẵn sàng! Chạy lệnh:');
        print('   flutter run -d chrome --release');

        break; // Dừng lại khi tìm thấy model hoạt động
      } else {
        print('   ⚠️ Response rỗng');
        print('');
      }
    } catch (e) {
      print('   ❌ LỖI: $e');
      print('');

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('404') || errorStr.contains('not found')) {
        print('   💡 Model $modelName không khả dụng');
        print('   → Thử model khác...');
      } else if (errorStr.contains('403') || errorStr.contains('api key')) {
        print('   💡 API key không hợp lệ hoặc không có quyền');
        print('   → Tạo key mới: https://aistudio.google.com/app/apikey');
        break; // Dừng nếu lỗi API key
      } else if (errorStr.contains('429') || errorStr.contains('quota')) {
        print('   💡 Đã vượt quota');
        print('   → Đợi 1 phút rồi thử lại');
        break;
      } else {
        print('   💡 Lỗi không xác định, thử model khác...');
      }

      print('');
    }

    // Đợi 2 giây giữa các lần test để tránh rate limit
    if (modelName != modelsToTest.last) {
      await Future.delayed(Duration(seconds: 2));
    }
  }

  print('');
  print('=' * 50);
  print('✅ TEST HOÀN TẤT');
  print('');
  print('📖 Xem hướng dẫn chi tiết trong: GEMINI_SETUP_GUIDE.md');
}
