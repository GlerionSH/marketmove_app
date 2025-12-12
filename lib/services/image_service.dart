import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/services/session_service.dart';

/// Service for handling image uploads to Supabase Storage.
/// Supports Web and Desktop platforms.
class ImageService {
  static const String _bucketName = 'marketmove-images';
  static final _supabase = Supabase.instance.client;

  /// Pick an image file from the device.
  /// Returns file bytes and file name, or null if cancelled.
  static Future<({Uint8List bytes, String fileName})?> pickImage() async {
    try {
      print('[ImageService] pickImage: Opening file picker...');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        print('[ImageService] pickImage: User cancelled file selection');
        return null;
      }

      final file = result.files.first;
      
      if (file.bytes == null) {
        print('[ImageService] pickImage: File bytes are null');
        return null;
      }

      print('[ImageService] pickImage: Selected file: ${file.name}, size: ${file.bytes!.length} bytes');
      
      return (bytes: file.bytes!, fileName: file.name);
    } catch (e) {
      print('[ImageService] pickImage ERROR: $e');
      return null;
    }
  }

  /// Upload an image to Supabase Storage.
  /// Returns the public URL of the uploaded image.
  static Future<String?> uploadImage({
    required Uint8List fileBytes,
    required String fileName,
    required String folder, // 'productos' or 'gastos'
  }) async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) {
        print('[ImageService] uploadImage ERROR: User not authenticated');
        return null;
      }

      // Generate unique file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = '${timestamp}_$fileName';
      final storagePath = '$userId/$folder/$uniqueFileName';

      print('[ImageService] uploadImage: Uploading to path: $storagePath');

      // Upload to Supabase Storage
      await _supabase.storage.from(_bucketName).uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(extension),
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(storagePath);
      
      print('[ImageService] uploadImage: Success! URL: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      print('[ImageService] uploadImage ERROR: $e');
      return null;
    }
  }

  /// Delete an image from Supabase Storage if it exists.
  static Future<bool> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      print('[ImageService] deleteImage: No image URL provided');
      return true;
    }

    try {
      // Extract the path from the URL
      final path = _extractPathFromUrl(imageUrl);
      if (path == null) {
        print('[ImageService] deleteImage: Could not extract path from URL');
        return false;
      }

      print('[ImageService] deleteImage: Deleting path: $path');

      await _supabase.storage.from(_bucketName).remove([path]);
      
      print('[ImageService] deleteImage: Success!');
      return true;
    } catch (e) {
      print('[ImageService] deleteImage ERROR: $e');
      return false;
    }
  }

  /// Upload a new image and delete the old one if it exists.
  /// Returns the new public URL, or null if upload failed.
  static Future<String?> uploadAndReplace({
    required Uint8List fileBytes,
    required String fileName,
    required String folder,
    String? previousUrl,
  }) async {
    try {
      print('[ImageService] uploadAndReplace: Starting...');
      
      // Upload new image first
      final newUrl = await uploadImage(
        fileBytes: fileBytes,
        fileName: fileName,
        folder: folder,
      );

      if (newUrl == null) {
        print('[ImageService] uploadAndReplace: Upload failed');
        return null;
      }

      // Delete old image if exists
      if (previousUrl != null && previousUrl.isNotEmpty) {
        print('[ImageService] uploadAndReplace: Deleting previous image...');
        await deleteImage(previousUrl);
      }

      print('[ImageService] uploadAndReplace: Complete! New URL: $newUrl');
      return newUrl;
    } catch (e) {
      print('[ImageService] uploadAndReplace ERROR: $e');
      return null;
    }
  }

  /// Get the public URL for a storage path.
  static String getPublicUrl(String path) {
    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }

  /// Extract the storage path from a public URL.
  static String? _extractPathFromUrl(String url) {
    try {
      // URL format: https://xxx.supabase.co/storage/v1/object/public/marketmove-images/userId/folder/filename
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      
      // Find the bucket name index and get everything after it
      final bucketIndex = segments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= segments.length - 1) {
        return null;
      }
      
      return segments.sublist(bucketIndex + 1).join('/');
    } catch (e) {
      print('[ImageService] _extractPathFromUrl ERROR: $e');
      return null;
    }
  }

  /// Get content type based on file extension.
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  /// Check if a URL is a valid image URL from our storage.
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains(_bucketName);
  }
}
