import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Compress image to reduce file size
  Future<Uint8List> compressImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      
      // Decode the image
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large (max 512x512 for avatars)
      if (image.width > 512 || image.height > 512) {
        image = img.copyResize(
          image,
          width: 512,
          height: 512,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with quality 85
      final compressed = img.encodeJpg(image, quality: 85);
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Upload avatar to Supabase Storage
  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      // Compress the image
      final compressedImage = await compressImage(imageFile);

      // Generate unique filename with user ID as folder
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar-$timestamp.jpg';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage
      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            compressedImage,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Delete old avatar from storage
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the path after 'object/public/avatars'
      final avatarsIndex = pathSegments.indexOf('avatars');
      if (avatarsIndex == -1 || avatarsIndex >= pathSegments.length - 1) {
        return; // Invalid URL format
      }

      // Get the path after 'avatars/' (userId/filename)
      final filePath = pathSegments.sublist(avatarsIndex + 1).join('/');

      // Delete from storage
      await supabase.storage.from('avatars').remove([filePath]);
    } catch (e) {
      // Silently fail - old avatar might not exist
      print('Failed to delete old avatar: $e');
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog() async {
    // This will be implemented in the UI layer
    // Returning null for now
    return null;
  }
}
