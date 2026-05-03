import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/photo.dart';
import '../../../core/services/image_service.dart';

class PhotoService {
  final supabase = Supabase.instance.client;
  final _imageService = ImageService();

  /// Get photos for a circle
  Future<List<Photo>> getCirclePhotos(String circleId) async {
    try {
      // Get photos from the circle (without user join for now)
      final response = await supabase
          .from('photos')
          .select('*')
          .eq('circle_id', circleId)
          .order('taken_at', ascending: false);

      // Get user details separately
      final photos = <Photo>[];
      for (final data in response) {
        try {
          // Get user details from users table
          final userResponse = await supabase
              .from('users')
              .select('display_name, avatar_url')
              .eq('id', data['user_id'])
              .maybeSingle();

          photos.add(Photo.fromJson({
            ...data,
            'uploader_name': userResponse?['display_name'],
            'uploader_avatar': userResponse?['avatar_url'],
          }));
        } catch (e) {
          // If user fetch fails, add photo without user details
          photos.add(Photo.fromJson(data));
        }
      }

      return photos;
    } catch (e) {
      throw Exception('Failed to load photos: $e');
    }
  }

  /// Get all photos from user's circles
  Future<List<Photo>> getUserPhotos() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's circles
      final circlesResponse = await supabase
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId);

      final circleIds = circlesResponse
          .map((row) => row['circle_id'] as String)
          .toList();

      if (circleIds.isEmpty) return [];

      // Get photos from those circles (without user join for now)
      final response = await supabase
          .from('photos')
          .select('*')
          .inFilter('circle_id', circleIds)
          .order('taken_at', ascending: false);

      // Get user details separately
      final photos = <Photo>[];
      for (final data in response) {
        try {
          // Get user details from users table
          final userResponse = await supabase
              .from('users')
              .select('display_name, avatar_url')
              .eq('id', data['user_id'])
              .maybeSingle();

          photos.add(Photo.fromJson({
            ...data,
            'uploader_name': userResponse?['display_name'],
            'uploader_avatar': userResponse?['avatar_url'],
          }));
        } catch (e) {
          // If user fetch fails, add photo without user details
          photos.add(Photo.fromJson(data));
        }
      }

      return photos;
    } catch (e) {
      throw Exception('Failed to load photos: $e');
    }
  }

  /// Upload a photo
  Future<Photo> uploadPhoto({
    required File imageFile,
    required String circleId,
    String? caption,
    String? location,
    DateTime? takenAt,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Compress and upload image
      final imageUrl = await _uploadImageToStorage(imageFile, userId);

      // Create photo record
      final response = await supabase
          .from('photos')
          .insert({
            'circle_id': circleId,
            'user_id': userId,
            'url': imageUrl,
            'caption': caption,
            'location': location,
            'taken_at': (takenAt ?? DateTime.now()).toIso8601String(),
          })
          .select()
          .single();

      return Photo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<String> _uploadImageToStorage(File imageFile, String userId) async {
    try {
      // Compress the image
      final compressedImage = await _imageService.compressImage(imageFile);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo-$timestamp.jpg';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage
      await supabase.storage.from('photos').uploadBinary(
            filePath,
            compressedImage,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage.from('photos').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId, String photoUrl) async {
    try {
      // Delete from database
      await supabase.from('photos').delete().eq('id', photoId);

      // Delete from storage
      await _deleteImageFromStorage(photoUrl);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  Future<void> _deleteImageFromStorage(String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      final photosIndex = pathSegments.indexOf('photos');
      if (photosIndex == -1 || photosIndex >= pathSegments.length - 1) {
        return;
      }

      final filePath = pathSegments.sublist(photosIndex + 1).join('/');
      await supabase.storage.from('photos').remove([filePath]);
    } catch (e) {
      print('Failed to delete image from storage: $e');
    }
  }

  /// Update photo caption
  Future<void> updateCaption(String photoId, String caption) async {
    try {
      await supabase
          .from('photos')
          .update({'caption': caption})
          .eq('id', photoId);
    } catch (e) {
      throw Exception('Failed to update caption: $e');
    }
  }
}
