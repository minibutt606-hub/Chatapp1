import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Reduce quality for faster uploads
      );
      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      print("Error taking photo: $e");
    }
    return null;
  }

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
    return null;
  }

  static Future<File?> takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
      );
      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      print("Error taking video: $e");
    }
    return null;
  }

  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      print("Error picking video: $e");
    }
    return null;
  }
}
