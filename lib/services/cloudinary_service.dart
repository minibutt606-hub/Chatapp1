import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class CloudinaryService {
  static final cloudinary = CloudinaryPublic('dyqwodji3', 'flutter_upload', cache: false);

  static Future<String?> uploadFile(String filePath, {CloudinaryResourceType resourceType = CloudinaryResourceType.Image}) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath, resourceType: resourceType),
      );

      // Returns the secure URL of the uploaded image/video
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print("Cloudinary Error: ${e.message}");
      return null;
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }
}
