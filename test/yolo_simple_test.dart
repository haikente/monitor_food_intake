import 'package:flutter/material.dart';
import 'package:monitor_food_intake/services/yolo_detection_service.dart';

/// Simple test để verify YOLO model có load được không
void main() async {
  print('🧪 SIMPLE YOLO MODEL TEST\n');
  print('=' * 50);

  try {
    // Initialize Flutter bindings (cần cho asset loading)
    WidgetsFlutterBinding.ensureInitialized();

    // Test 1: Initialize service
    print('\n1️⃣ Initializing YoloDetectionService...');
    final yoloService = YoloDetectionService();

    print('   Loading model from assets/models/yolov8n.tflite...');
    await yoloService.initialize();

    print('   ✅ Model loaded successfully!');
    print('   ✅ YoloDetectionService is ready to use');

    // Test 2: Verify service can be disposed
    print('\n2️⃣ Testing cleanup...');
    yoloService.dispose();
    print('   ✅ Service disposed successfully');

    print('\n' + '=' * 50);
    print('✅ ALL TESTS PASSED!');
    print('=' * 50);
    print('\n💡 Next step: Test with actual image in your app');
  } catch (e, stackTrace) {
    print('\n❌ TEST FAILED: $e');
    print('\nStack trace:');
    print(stackTrace);
    print('\n💡 Common issues:');
    print('   - Model file not found: Run "flutter pub get" first');
    print('   - TFLite error: Check model file is valid');
  }
}
