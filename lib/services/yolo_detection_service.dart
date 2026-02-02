import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;


class YoloDetectionService {
  Interpreter? _interpreter;
  static const int _inputSize = 640; // YOLOv8 input size
  static const double _confidenceThreshold = 0.25;
  static const double _iouThreshold = 0.45;


  static const Map<int, String> _cocoFoodClasses = {
    46: 'banana',
    47: 'apple',
    48: 'sandwich',
    49: 'orange',
    50: 'broccoli',
    51: 'carrot',
    52: 'hot dog',
    53: 'pizza',
    54: 'donut',
    55: 'cake',
    41: 'cup',
    42: 'fork',
    43: 'knife',
    44: 'spoon',
    45: 'bowl',
  };

  /// Khởi tạo TFLite interpreter với YOLOv8 model
Future<void> initialize() async {
try {
  _interpreter = await Interpreter.fromAsset(
    'assets/models/yolov8n.tflite',
    options: InterpreterOptions()..threads = 4,
  );
  } catch (e) {
    throw(Exception("Lỗi tải model"));
  }
}

Future<List<DetectionResult>> detectObjects(File imageFile) async {
  if (_interpreter == null) {
    throw Exception(
      'YOLO interpreter chưa được khởi tạo. Gọi initialize() trước.');
  }

  try {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể đọc ảnh');
    }

    final originalWidth = image.width;
    final originalHeight = image.height;

    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
    );

    final inputTensor = _imageToTensor(resized);

     
    final output = List.generate(
      1,
      (_) => List.generate(
        84,
      (_) => List<double>.filled(8400, 0.0),
    ),
  );


  final stopwatch = Stopwatch()..start();
    _interpreter!.run(inputTensor, output);
    stopwatch.stop();
    // Post-process: NMS và filter
    final detections = _postProcess(
      output,
      originalWidth,
      originalHeight,
    );
    return detections;
  } catch (e) {
    rethrow;
  }
}

  /// Chuyển ảnh sang tensor [1, 640, 640, 3] với normalization
List<List<List<List<double>>>> _imageToTensor(img.Image image) {
final tensor = List.generate(
  1,
  (_) => List.generate(
      _inputSize,
      (_) => List.generate(
      _inputSize,
      (_) => List<double>.filled(3, 0.0),
      ),
    ),
  );
  // YOLOv8 expects RGB format normalized to [0, 1]
for (var y = 0; y < _inputSize; y++) {
    for (var x = 0; x < _inputSize; x++) {
      final pixel = image.getPixel(x, y);
      tensor[0][y][x][0] = pixel.r / 255.0;
      tensor[0][y][x][1] = pixel.g / 255.0;
      tensor[0][y][x][2] = pixel.b / 255.0;
    }
  }
  return tensor;
}

  /// Post-process YOLO output: NMS + filtering
List<DetectionResult> _postProcess(
  List<List<List<double>>> output,
  int originalWidth,
  int originalHeight,
) {
  final detections = <DetectionResult>[];
  final predictions = output[0];
  for (var i = 0; i < 8400; i++) {
    final x = predictions[0][i];
    final y = predictions[1][i];
    final w = predictions[2][i];
    final h = predictions[3][i];
  
    // Get class scores (index 4-83)
    double maxScore = 0;
    int maxClassId = -1;
    for (var classId = 0; classId < 80; classId++) {
      final score = predictions[4 + classId][i];
       if (score > maxScore) {
        maxScore = score;
        maxClassId = classId;
      }
    }
    // Filter by confidence
    if (maxScore < _confidenceThreshold) continue;
    // Filter only food-related classes
    if (!_cocoFoodClasses.containsKey(maxClassId)) continue;
    // Convert to original image coordinates
    final scaleX = originalWidth / _inputSize;
    final scaleY = originalHeight / _inputSize;

    final x1 = ((x - w / 2) * scaleX).clamp(0, originalWidth.toDouble());
    final y1 = ((y - h / 2) * scaleY).clamp(0, originalHeight.toDouble());
    final x2 = ((x + w / 2) * scaleX).clamp(0, originalWidth.toDouble());
    final y2 = ((y + h / 2) * scaleY).clamp(0, originalHeight.toDouble());

    detections.add(DetectionResult(
      classId: maxClassId,
      className: _cocoFoodClasses[maxClassId] ?? 'unknown',
      confidence: maxScore,
      bbox: BoundingBox(
        x1: x1.toInt(),
        y1: y1.toInt(),
        x2: x2.toInt(),
        y2: y2.toInt(),
      ),
    ));
  }

  // Apply NMS
  final nmsResults = _nonMaxSuppression(detections);
  return nmsResults;
}

  /// Non-Maximum Suppression để loại bỏ duplicate boxes
  List<DetectionResult> _nonMaxSuppression(List<DetectionResult> detections) {
    // Sort by confidence descending
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected = <DetectionResult>[];

    for (var i = 0; i < detections.length; i++) {
      final current = detections[i];
      bool keep = true;

      for (var j = 0; j < selected.length; j++) {
        final iou = _calculateIoU(current.bbox, selected[j].bbox);
        if (iou > _iouThreshold) {
          keep = false;
          break;
        }
      }

      if (keep) {
        selected.add(current);
      }
    }

    return selected;
  }

  /// Tính IoU (Intersection over Union) giữa 2 bounding boxes
  double _calculateIoU(BoundingBox box1, BoundingBox box2) {
    final x1 = box1.x1 > box2.x1 ? box1.x1 : box2.x1;
    final y1 = box1.y1 > box2.y1 ? box1.y1 : box2.y1;
    final x2 = box1.x2 < box2.x2 ? box1.x2 : box2.x2;
    final y2 = box1.y2 < box2.y2 ? box1.y2 : box2.y2;

    if (x2 < x1 || y2 < y1) return 0.0;

    final intersection = (x2 - x1) * (y2 - y1);
    final area1 = (box1.x2 - box1.x1) * (box1.y2 - box1.y1);
    final area2 = (box2.x2 - box2.x1) * (box2.y2 - box2.y1);
    final union = area1 + area2 - intersection;

    return intersection / union;
  }

  /// Crop ảnh theo bounding box
  Future<File> cropImage(File imageFile, BoundingBox bbox) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Không thể đọc ảnh');
    }

    // Crop
    final cropped = img.copyCrop(
      image,
      x: bbox.x1,
      y: bbox.y1,
      width: bbox.x2 - bbox.x1,
      height: bbox.y2 - bbox.y1,
    );

    // Save to temp file
    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(cropped));

    return tempFile;
  }

  /// Cleanup
void dispose() {
  _interpreter?.close();
 }
}

/// Kết quả phát hiện object
class DetectionResult {
  final int classId;
  final String className;
  final double confidence;
  final BoundingBox bbox;

  DetectionResult({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.bbox,
  });

  @override
  String toString() {
    return 'DetectionResult(class: $className, conf: ${(confidence * 100).toStringAsFixed(1)}%, bbox: $bbox)';
  }
}

/// Bounding box (tọa độ x1, y1, x2, y2)
class BoundingBox {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  int get width => x2 - x1;
  int get height => y2 - y1;
  int get area => width * height;

  @override
  String toString() {
    return 'BoundingBox(x1: $x1, y1: $y1, x2: $x2, y2: $y2, ${width}x$height)';
  }
}
