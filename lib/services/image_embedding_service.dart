import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageEmbeddingService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Model paths
  static const String _modelPath =
      'assets/models/mobilenet_v3_embedding.tflite';

  /// Model input/output shapes
  static const int _inputSize = 224;
  static const int _embeddingSize = 512;

  /// Initialize the embedding model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🧠 Initializing Image Embedding Model...');

      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      print('✅ Image Embedding Model loaded');
      print('   - Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('   - Output shape: ${_interpreter!.getOutputTensor(0).shape}');

      _isInitialized = true;
    } catch (e) {
      print('❌ Failed to load embedding model: $e');
      throw Exception('Cannot initialize Image Embedding Model: $e');
    }
  }

  /// Generate embedding vector from image file
  ///
  /// Returns: List<double> with length 512 (normalized L2)
  Future<List<double>> generateEmbedding(File imageFile) async {
    if (!_isInitialized) {
      throw Exception(
          'ImageEmbeddingService not initialized. Call initialize() first.');
    }

    try {
      // 1. Load and decode image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Cannot decode image');
      }

      // 2. Preprocess image
      final inputTensor = _preprocessImage(image);

      // 3. Run inference
      final outputTensor =
          List.filled(_embeddingSize, 0.0).reshape([1, _embeddingSize]);
      _interpreter!.run(inputTensor, outputTensor);

      // 4. Extract and normalize embedding
      final embedding = (outputTensor[0] as List).cast<double>();
      final normalizedEmbedding = _l2Normalize(embedding);

      return normalizedEmbedding;
    } catch (e) {
      print('❌ Error generating embedding: $e');
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Generate embeddings for multiple cropped images (from YOLO)
  ///
  /// Returns: List of embeddings, one for each crop
  Future<List<List<double>>> generateEmbeddingsForCrops(
      List<File> cropFiles) async {
    final embeddings = <List<double>>[];

    for (final cropFile in cropFiles) {
      final embedding = await generateEmbedding(cropFile);
      embeddings.add(embedding);
    }

    return embeddings;
  }

  /// Preprocess image for MobileNetV3
  ///
  /// Steps:
  /// 1. Resize to 224x224
  /// 2. Normalize to [0, 1]
  /// 3. Convert to Float32 tensor
  Float32List _preprocessImage(img.Image image) {
    // Resize to model input size
    final resized =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    // Convert to Float32List [1, 224, 224, 3]
    final inputSize = 1 * _inputSize * _inputSize * 3;
    final input = Float32List(inputSize);

    int pixelIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);

        // Normalize to [0, 1]
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// L2 Normalization of embedding vector
  ///
  /// Formula: v_normalized = v / ||v||_2
  /// Makes all embeddings have unit length for cosine similarity
  List<double> _l2Normalize(List<double> vector) {
    double norm = 0.0;
    for (final value in vector) {
      norm += value * value;
    }
    norm = math.sqrt(norm);

    if (norm == 0.0) {
      return vector; // Avoid division by zero
    }

    return vector.map((v) => v / norm).toList();
  }

  /// Calculate cosine similarity between two embeddings
  ///
  /// Since embeddings are L2-normalized, this is just dot product
  /// Returns: -1.0 (opposite) to 1.0 (identical)
  static double cosineSimilarity(
      List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embeddings must have same length');
    }

    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }

    return dotProduct;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
