import 'dart:io';
import 'package:monitor_food_intake/services/yolo_detection_service.dart';

/// Test script để verify YOLOv8 TFLite model
void main() async {
  print('🧪 TESTING YOLO DETECTION SERVICE\n');
  print('=' * 50);

  try {
    // 1. Initialize service
    print('\n1️⃣ Initializing YoloDetectionService...');
    final yoloService = YoloDetectionService();
    await yoloService.initialize();
    print('   ✅ Service initialized successfully');

    // 2. Test với ảnh mẫu (cần có ảnh test)
    print('\n2️⃣ Testing object detection...');

    // Thay đổi path này thành ảnh test của bạn
    final testImagePath = 'path/to/your/test/image.jpg';
    final testImage = File(testImagePath);

    if (!await testImage.exists()) {
      print('   ⚠️ Test image not found: $testImagePath');
      print('   💡 Please provide a test image path');
      return;
    }

    print('   📸 Analyzing: $testImagePath');
    final detections = await yoloService.detectObjects(testImage);

    // 3. Display results
    print('\n3️⃣ Detection Results:');
    print('   Found ${detections.length} objects\n');

    if (detections.isEmpty) {
      print('   ⚠️ No food objects detected');
      print('   💡 Try with an image containing food items');
    } else {
      for (var i = 0; i < detections.length; i++) {
        final detection = detections[i];
        print('   ${i + 1}. ${detection.className}');
        print(
            '      Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%');
        print('      BBox: ${detection.bbox}');
        print('');
      }

      // 4. Test cropping
      print('4️⃣ Testing image cropping...');
      final firstDetection = detections.first;
      final croppedImage = await yoloService.cropImage(
        testImage,
        firstDetection.bbox,
      );
      print('   ✅ Cropped image saved: ${croppedImage.path}');
    }

    // 5. Cleanup
    print('\n5️⃣ Cleaning up...');
    yoloService.dispose();
    print('   ✅ Service disposed');

    print('\n' + '=' * 50);
    print('✅ ALL TESTS PASSED!');
    print('=' * 50);
  } catch (e, stackTrace) {
    print('\n❌ TEST FAILED: $e');
    print('\nStack trace:');
    print(stackTrace);
  }
}
