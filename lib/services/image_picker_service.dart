import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Service xử lý chọn/chụp ảnh
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Chụp ảnh từ camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85, // Compress để giảm kích thước
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi chụp ảnh: $e');
    }
  }

  /// Chọn ảnh từ thư viện
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi chọn ảnh: $e');
    }
  }

  /// Hiển thị dialog cho user chọn camera hoặc gallery
  static Future<File?> showImageSourceDialog({
    required Future<File?> Function() onCamera,
    required Future<File?> Function() onGallery,
  }) async {
    // This will be handled in the UI layer
    throw UnimplementedError('Use showModalBottomSheet in UI');
  }
}
