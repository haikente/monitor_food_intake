import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Service chạy model phân loại món ăn (EfficientNet) offline
class LocalFoodClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const int _inputSize = 224; // EfficientNet-Lite4 input size
  static const String _modelPath = 'assets/models/efficientnet_lite4.tflite';
  static const String _labelsPath = 'assets/models/efficientnet_labels.txt';

  /// Khởi tạo model và load labels
  Future<void> initialize() async {
    try {
      print('🤖 Loading Local Food Classifier (EfficientNet)...');

      // Load model
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: InterpreterOptions()..threads = 4,
      );

      // Load labels
      final labelData = await rootBundle.loadString(_labelsPath);
      _labels = labelData.split('\n').where((l) => l.isNotEmpty).toList();

    } catch (e) {
      rethrow;
    }
  }

  /// Phân loại hình ảnh
  Future<List<ClassificationResult>> classify(File imageFile,
      {int topK = 3}) async {
    if (_interpreter == null) throw Exception('Interpreter not initialized');
    if (_labels == null) throw Exception('Labels not loaded');

    try {
      // 1. Preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Cannot decode image');

      // Resize to 224x224
      final resized =
          img.copyResize(image, width: _inputSize, height: _inputSize);

      // Convert to tensor [1, 224, 224, 3] (UInt8 for quantized model)
      final input = _imageToUint8List(resized);

      // 2. Prepare output
      // Output shape: [1, 1001] (ImageNet classes)
      final outputBuffer = List.filled(1 * 1001, 0).reshape([1, 1001]);

      // 3. Run inference
      _interpreter!.run(input, outputBuffer);

      // 4. Process results
      final output = outputBuffer[0]
          as List<int>; // Quantized uint8 outputs usually map to prob

      // Create list of (index, score)
      final scoredResults = <_ScoredLabel>[];
      for (var i = 0; i < output.length; i++) {
        // Với model quantized uint8, output thường là 0-255
        // Cần xem lại output type thực tế của model EfficientNet-Lite4 cụ thể này
        // Nhưng thường là uint8 -> chia 255.0 để ra probability
        // Một số model efficientnet output là float32.
        // Logic ở đây giả định uint8 input/output như file name gợi ý (efficientnet_lite4_uint8)
        scoredResults.add(_ScoredLabel(i, output[i].toDouble() / 255.0));
      }

      // Sort descending
      scoredResults.sort((a, b) => b.score.compareTo(a.score));

      // Get top K
      final results = <ClassificationResult>[];
      for (var i = 0; i < topK && i < scoredResults.length; i++) {
        final item = scoredResults[i];
        if (item.index < _labels!.length) {
          results.add(ClassificationResult(
            label: _labels![item.index],
            confidence: item.score,
          ));
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Convert image to Uint8List for TFLite [1, 224, 224, 3]
  List<List<List<List<int>>>> _imageToUint8List(img.Image image) {
    final buffer = List.generate(
        1,
        (_) => List.generate(_inputSize,
            (_) => List.generate(_inputSize, (_) => List<int>.filled(3, 0))));

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        buffer[0][y][x][0] = pixel.r.toInt();
        buffer[0][y][x][1] = pixel.g.toInt();
        buffer[0][y][x][2] = pixel.b.toInt();
      }
    }

    return buffer;
  }
}

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult({required this.label, required this.confidence});

  @override
  String toString() => '$label: ${(confidence * 100).toStringAsFixed(1)}%';
}

class _ScoredLabel {
  final int index;
  final double score;
  _ScoredLabel(this.index, this.score);
}
