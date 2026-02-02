import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/image_picker_service.dart';
import '../../services/hybrid_food_analysis_service.dart';
import '../../services/hybrid_image_based_analysis_service.dart';
import 'result_screen.dart';
import 'history_screen_bloc.dart';

/// Màn hình chính - Chụp/chọn ảnh để phân tích
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _selectedAI = 'hybrid'; // 'hybrid', 'ensemble'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi khẩu phần ăn',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreenBloc(),
                ),
              );
            },
            tooltip: 'Lịch sử',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Icon(
                Icons.restaurant_menu,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'AI Phân Tích Bữa Ăn',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Chụp hoặc chọn ảnh bữa ăn để AI phân tích\ndinh dưỡng và đưa ra lời khuyên',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),

              // AI Model Selector
              _buildAISelector(),
              const SizedBox(height: 24),

              // Preview ảnh đã chọn
              if (_selectedImage != null) ...[
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Buttons
              if (!_isAnalyzing) ...[
                // Camera button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Chụp ảnh bữa ăn',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gallery button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 28),
                    label: const Text(
                      'Chọn từ thư viện',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Analyze button (chỉ hiện khi đã chọn ảnh)
                if (_selectedImage != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _analyzeImage,
                      icon: const Icon(Icons.analytics, size: 28),
                      label: const Text(
                        'Phân tích với AI',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Loading state
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Đang phân tích bữa ăn...',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI đang xử lý ảnh của bạn',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],

              const SizedBox(height: 40),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI sẽ nhận diện món ăn, tính calories và chỉ số GI',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chụp ảnh từ camera
  Future<void> _takePhoto() async {
    try {
      final image = await _imagePickerService.takePhoto();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi chụp ảnh', e.toString());
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePickerService.pickFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi chọn ảnh', e.toString());
    }
  }

  /// Phân tích ảnh với AI
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() {
      _isAnalyzing = true;
    });

    try {
      if (_selectedAI == 'hybrid') {
        final hybridService = HybridFoodAnalysisService();
        await hybridService.initialize();

        final analysis =
            await hybridService.analyzeWithDatabase(_selectedImage!);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(analysis: analysis),
            ),
          );
        }
      } else if (_selectedAI == 'ensemble') {
        final ensembleService = HybridImageBasedAnalysisService();
        await ensembleService.initialize(
            foodImagesDir: 'assets/data/database_images');

        final analysis =
            await ensembleService.analyzeWithImageSearch(_selectedImage!);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(analysis: analysis),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi phân tích', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  /// Hiển thị dialog lỗi
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Widget chọn AI model
  Widget _buildAISelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                '🧪 Chọn AI Model',
                style: TextStyle(
                  color: Colors.amber[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              RadioListTile<String>(
                title: const Text('🎯 Hybrid (YOLO + Gemini + DB)'),
                subtitle: const Text('1,275 món Việt',
                    style: TextStyle(fontSize: 11)),
                value: 'hybrid',
                // ignore: deprecated_member_use
                groupValue: _selectedAI,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  setState(() {
                    _selectedAI = value!;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
               ),
            ],
          ),
        ],
      ),
    );
  }
}
