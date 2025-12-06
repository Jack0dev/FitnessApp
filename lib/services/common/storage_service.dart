import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

/// Storage Service using Supabase Storage
/// Falls back to Base64 if Supabase Storage is not available
class StorageService {
  /// Check if Supabase is initialized safely
  /// Returns true only if Supabase is both configured and initialized
  bool _isSupabaseInitialized() {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }
    try {
      // Accessing Supabase.instance may throw if not initialized
      return Supabase.instance.isInitialized;
    } catch (e) {
      // Supabase.instance throws error if not initialized
      return false;
    }
  }

  /// Upload image to Supabase Storage
  /// Returns public URL if successful, null if failed
  Future<String?> uploadImage({
    required File imageFile,
    required String userId,
    String folder = 'profile_images',
  }) async {
    // Check if Supabase is configured
    if (!SupabaseConfig.isConfigured) {
      print('⚠️ Supabase not configured. Check supabase_config.dart');
      return null;
    }
    
    // Check if Supabase is initialized safely
    if (!_isSupabaseInitialized()) {
      print('⚠️ Supabase not initialized. Check main.dart initialization.');
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      final bucketName = SupabaseConfig.storageBucketName;
      
      // Generate unique filename
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$folder/$fileName';

      print('📤 Uploading image to Supabase Storage...');
      print('   Bucket: $bucketName');
      print('   Path: $filePath');

      // Upload to Supabase Storage
      // Note: Bucket name should match what you created in Supabase Dashboard
      await supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true, // Replace if exists
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('✅ Image uploaded successfully!');
      print('   URL: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      // Upload failed - log error for debugging
      print('❌ Supabase Storage upload failed:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      
      // Check for common errors
      if (e.toString().contains('Bucket not found') || 
          e.toString().contains('does not exist')) {
        print('⚠️ Bucket "${SupabaseConfig.storageBucketName}" not found!');
        print('   Please check your Supabase Dashboard and create the bucket,');
        print('   or update storageBucketName in supabase_config.dart');
      } else if (e.toString().contains('permission') || 
                 e.toString().contains('policy') ||
                 e.toString().contains('403')) {
        print('⚠️ Permission denied! Check Storage Policies in Supabase Dashboard.');
        print('   Make sure INSERT policy is set for authenticated users.');
      } else if (e.toString().contains('401') || 
                 e.toString().contains('unauthorized')) {
        print('⚠️ Authentication failed!');
        print('   Note: Supabase Storage requires authentication.');
        print('   Since we use Supabase Auth, you may need to set up RLS policies');
        print('   that allow authenticated users to access storage buckets.');
      }
      
      return null;
    }
  }

  /// Upload video to Supabase Storage
  /// Returns public URL if successful, null if failed
  Future<String?> uploadVideo({
    required File videoFile,
    required String userId,
    String folder = 'course_lessons',
  }) async {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      final bucketName = SupabaseConfig.storageBucketName;
      
      // Generate unique filename
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '$folder/$fileName';

      print('📤 Uploading video to Supabase Storage...');
      print('   Bucket: $bucketName');
      print('   Path: $filePath');

      // Upload to Supabase Storage
      await supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            videoFile,
            fileOptions: const FileOptions(
              contentType: 'video/mp4',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('✅ Video uploaded successfully!');
      print('   URL: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      print('❌ Supabase Storage upload failed:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      return null;
    }
  }

  /// Upload lesson file (image or video) to Supabase Storage
  /// Returns public URL if successful, null if failed
  Future<String?> uploadLessonFile({
    required File file,
    required String userId,
    required String courseId,
    required bool isVideo,
  }) async {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      final bucketName = SupabaseConfig.storageBucketName;
      
      // Generate unique filename
      final extension = isVideo ? 'mp4' : 'jpg';
      final fileName = '${courseId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final folder = 'course_lessons';
      final filePath = '$folder/$fileName';

      print('📤 Uploading lesson file to Supabase Storage...');
      print('   Bucket: $bucketName');
      print('   Path: $filePath');
      print('   Type: ${isVideo ? "video" : "image"}');

      // Upload to Supabase Storage
      await supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(
              contentType: isVideo ? 'video/mp4' : 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('✅ Lesson file uploaded successfully!');
      print('   URL: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      print('❌ Supabase Storage upload failed:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      return null;
    }
  }

  /// Delete image from Supabase Storage
  Future<bool> deleteImage({
    required String fileUrl,
    String folder = 'profile_images',
  }) async {
    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized()) {
      return false;
    }

    try {
      final supabase = Supabase.instance.client;
      final bucketName = SupabaseConfig.storageBucketName;
      
      // Extract file path from URL
      // Supabase public URL format: https://xxx.supabase.co/storage/v1/object/public/bucket/folder/file.jpg
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the path after bucket name
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        print('⚠️ Could not extract file path from URL: $fileUrl');
        return false;
      }
      
      // Get file path (everything after bucket name)
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete file
      await supabase.storage
          .from(bucketName)
          .remove([filePath]);

      print('✅ Image deleted successfully: $filePath');
      return true;
    } catch (e) {
      print('❌ Failed to delete image: $e');
      return false;
    }
  }
}
