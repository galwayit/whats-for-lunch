import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:drift/drift.dart';

import '../data/database/database.dart';

/// Comprehensive photo management service for meal and restaurant photos
class PhotoService {
  final AppDatabase _database;
  final ImagePicker _imagePicker = ImagePicker();

  // Photo storage configuration
  static const int _maxImageWidth = 1920;
  static const int _maxImageHeight = 1080;
  static const int _thumbnailSize = 300;
  static const int _jpegQuality = 85;
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  PhotoService(this._database);

  /// Check and request camera permissions
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Check and request photo library permissions
  Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;

    final result = await Permission.photos.request();
    return result.isGranted;
  }

  /// Take photo using device camera
  Future<PhotoResult?> takePhoto({
    required int userId,
    required String photoType,
    String? associatedEntityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check camera permission
      if (!await requestCameraPermission()) {
        throw PhotoException('Camera permission denied');
      }

      // Capture image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _jpegQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      return await _processAndSavePhoto(
        image,
        userId: userId,
        photoType: photoType,
        associatedEntityId: associatedEntityId,
        metadata: metadata,
      );
    } catch (e) {
      throw PhotoException('Failed to take photo: $e');
    }
  }

  /// Select photo from gallery
  Future<PhotoResult?> selectFromGallery({
    required int userId,
    required String photoType,
    String? associatedEntityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check photo permission
      if (!await requestPhotoPermission()) {
        throw PhotoException('Photo library permission denied');
      }

      // Select image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _jpegQuality,
      );

      if (image == null) return null;

      return await _processAndSavePhoto(
        image,
        userId: userId,
        photoType: photoType,
        associatedEntityId: associatedEntityId,
        metadata: metadata,
      );
    } catch (e) {
      throw PhotoException('Failed to select photo: $e');
    }
  }

  /// Select multiple photos from gallery
  Future<List<PhotoResult>> selectMultipleFromGallery({
    required int userId,
    required String photoType,
    String? associatedEntityId,
    Map<String, dynamic>? metadata,
    int maxImages = 5,
  }) async {
    try {
      // Check photo permission
      if (!await requestPhotoPermission()) {
        throw PhotoException('Photo library permission denied');
      }

      // Select multiple images
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _jpegQuality,
        limit: maxImages,
      );

      final List<PhotoResult> results = [];
      for (final image in images) {
        final result = await _processAndSavePhoto(
          image,
          userId: userId,
          photoType: photoType,
          associatedEntityId: associatedEntityId,
          metadata: metadata,
        );
        if (result != null) {
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      throw PhotoException('Failed to select photos: $e');
    }
  }

  /// Process and save photo to local storage
  Future<PhotoResult?> _processAndSavePhoto(
    XFile image, {
    required int userId,
    required String photoType,
    String? associatedEntityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Check file size
      if (imageBytes.length > _maxFileSizeBytes) {
        throw PhotoException('Image file is too large (max 5MB)');
      }

      // Decode and process image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw PhotoException('Invalid image format');
      }

      // Resize if necessary
      img.Image processedImage = originalImage;
      if (originalImage.width > _maxImageWidth || originalImage.height > _maxImageHeight) {
        processedImage = img.copyResize(
          originalImage,
          width: originalImage.width > originalImage.height ? _maxImageWidth : null,
          height: originalImage.height > originalImage.width ? _maxImageHeight : null,
        );
      }

      // Generate unique filename
      final String photoId = _generatePhotoId();
      final String fileName = '${photoId}_${photoType}.jpg';

      // Get app documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory photosDir = Directory(path.join(appDir.path, 'photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      // Save processed image
      final String filePath = path.join(photosDir.path, fileName);
      final Uint8List processedBytes = Uint8List.fromList(img.encodeJpg(processedImage, quality: _jpegQuality));
      await File(filePath).writeAsBytes(processedBytes);

      // Create thumbnail
      final img.Image thumbnail = img.copyResize(processedImage, width: _thumbnailSize);
      final String thumbnailFileName = '${photoId}_${photoType}_thumb.jpg';
      final String thumbnailPath = path.join(photosDir.path, thumbnailFileName);
      final Uint8List thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);

      // Save to database
      final photoCompanion = PhotosCompanion(
        id: Value(photoId),
        userId: Value(userId),
        fileName: Value(fileName),
        localPath: Value(filePath),
        fileSizeBytes: Value(processedBytes.length),
        width: Value(processedImage.width),
        height: Value(processedImage.height),
        contentType: const Value('image/jpeg'),
        photoType: Value(photoType),
        associatedEntityId: Value(associatedEntityId),
        metadata: Value(_encodeMetadata({
          ...?metadata,
          'thumbnailPath': thumbnailPath,
          'originalFileName': path.basename(image.path),
        })),
      );

      await _database.insertPhoto(photoCompanion);

      // Create result
      return PhotoResult(
        id: photoId,
        localPath: filePath,
        thumbnailPath: thumbnailPath,
        width: processedImage.width,
        height: processedImage.height,
        fileSizeBytes: processedBytes.length,
        photoType: photoType,
        associatedEntityId: associatedEntityId,
      );
    } catch (e) {
      throw PhotoException('Failed to process photo: $e');
    }
  }

  /// Get photo by ID
  Future<PhotoResult?> getPhotoById(String photoId) async {
    final photo = await _database.getPhotoById(photoId);
    if (photo == null) return null;

    final metadata = _decodeMetadata(photo.metadata);
    return PhotoResult(
      id: photo.id,
      localPath: photo.localPath,
      thumbnailPath: metadata['thumbnailPath'],
      width: photo.width,
      height: photo.height,
      fileSizeBytes: photo.fileSizeBytes,
      photoType: photo.photoType,
      associatedEntityId: photo.associatedEntityId,
      isUploaded: photo.isUploaded,
      cloudUrl: photo.cloudUrl,
      createdAt: photo.createdAt,
    );
  }

  /// Get photos by meal ID
  Future<List<PhotoResult>> getPhotosByMealId(String mealId) async {
    final photos = await _database.getPhotosByMealId(mealId);
    return photos.map((photo) {
      final metadata = _decodeMetadata(photo.metadata);
      return PhotoResult(
        id: photo.id,
        localPath: photo.localPath,
        thumbnailPath: metadata['thumbnailPath'],
        width: photo.width,
        height: photo.height,
        fileSizeBytes: photo.fileSizeBytes,
        photoType: photo.photoType,
        associatedEntityId: photo.associatedEntityId,
        isUploaded: photo.isUploaded,
        cloudUrl: photo.cloudUrl,
        createdAt: photo.createdAt,
      );
    }).toList();
  }

  /// Get photos by restaurant ID
  Future<List<PhotoResult>> getPhotosByRestaurantId(String restaurantId) async {
    final photos = await _database.getPhotosByRestaurantId(restaurantId);
    return photos.map((photo) {
      final metadata = _decodeMetadata(photo.metadata);
      return PhotoResult(
        id: photo.id,
        localPath: photo.localPath,
        thumbnailPath: metadata['thumbnailPath'],
        width: photo.width,
        height: photo.height,
        fileSizeBytes: photo.fileSizeBytes,
        photoType: photo.photoType,
        associatedEntityId: photo.associatedEntityId,
        isUploaded: photo.isUploaded,
        cloudUrl: photo.cloudUrl,
        createdAt: photo.createdAt,
      );
    }).toList();
  }

  /// Get all photos by user
  Future<List<PhotoResult>> getUserPhotos(int userId, {int limit = 50}) async {
    final photos = await _database.getPhotosByUserId(userId, limit: limit);
    return photos.map((photo) {
      final metadata = _decodeMetadata(photo.metadata);
      return PhotoResult(
        id: photo.id,
        localPath: photo.localPath,
        thumbnailPath: metadata['thumbnailPath'],
        width: photo.width,
        height: photo.height,
        fileSizeBytes: photo.fileSizeBytes,
        photoType: photo.photoType,
        associatedEntityId: photo.associatedEntityId,
        isUploaded: photo.isUploaded,
        cloudUrl: photo.cloudUrl,
        createdAt: photo.createdAt,
      );
    }).toList();
  }

  /// Delete photo
  Future<bool> deletePhoto(String photoId) async {
    try {
      // Mark as deleted in database
      await _database.markPhotoAsDeleted(photoId);

      // Get photo info to delete files
      final photo = await _database.getPhotoById(photoId);
      if (photo != null) {
        // Delete main file
        final file = File(photo.localPath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete thumbnail
        final metadata = _decodeMetadata(photo.metadata);
        final thumbnailPath = metadata['thumbnailPath'];
        if (thumbnailPath != null) {
          final thumbnailFile = File(thumbnailPath);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }
      }

      return true;
    } catch (e) {
      throw PhotoException('Failed to delete photo: $e');
    }
  }

  /// Apply basic image filter
  Future<PhotoResult?> applyFilter(String photoId, PhotoFilter filter) async {
    try {
      final photo = await _database.getPhotoById(photoId);
      if (photo == null) return null;

      // Load original image
      final file = File(photo.localPath);
      if (!await file.exists()) return null;

      final Uint8List imageBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Apply filter
      switch (filter) {
        case PhotoFilter.grayscale:
          image = img.grayscale(image);
          break;
        case PhotoFilter.sepia:
          image = img.sepia(image);
          break;
        case PhotoFilter.brightness:
          image = img.adjustColor(image, brightness: 1.2);
          break;
        case PhotoFilter.contrast:
          image = img.contrast(image, contrast: 120);
          break;
        case PhotoFilter.vintage:
          image = img.sepia(image);
          image = img.contrast(image, contrast: 110);
          break;
      }

      // Save filtered image
      final filteredId = '${photoId}_${filter.name}';
      final fileName = '${filteredId}_filtered.jpg';
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory photosDir = Directory(path.join(appDir.path, 'photos'));
      final String filePath = path.join(photosDir.path, fileName);
      
      final Uint8List filteredBytes = Uint8List.fromList(img.encodeJpg(image, quality: _jpegQuality));
      await File(filePath).writeAsBytes(filteredBytes);

      // Create thumbnail
      final img.Image thumbnail = img.copyResize(image, width: _thumbnailSize);
      final String thumbnailFileName = '${filteredId}_filtered_thumb.jpg';
      final String thumbnailPath = path.join(photosDir.path, thumbnailFileName);
      final Uint8List thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);

      // Save filtered photo to database
      final filteredPhotoCompanion = PhotosCompanion(
        id: Value(filteredId),
        userId: Value(photo.userId),
        fileName: Value(fileName),
        localPath: Value(filePath),
        fileSizeBytes: Value(filteredBytes.length),
        width: Value(image.width),
        height: Value(image.height),
        contentType: const Value('image/jpeg'),
        photoType: Value(photo.photoType),
        associatedEntityId: Value(photo.associatedEntityId),
        metadata: Value(_encodeMetadata({
          'thumbnailPath': thumbnailPath,
          'filter': filter.name,
          'originalPhotoId': photoId,
        })),
      );

      await _database.insertPhoto(filteredPhotoCompanion);

      return PhotoResult(
        id: filteredId,
        localPath: filePath,
        thumbnailPath: thumbnailPath,
        width: image.width,
        height: image.height,
        fileSizeBytes: filteredBytes.length,
        photoType: photo.photoType,
        associatedEntityId: photo.associatedEntityId,
      );
    } catch (e) {
      throw PhotoException('Failed to apply filter: $e');
    }
  }

  /// Get photo statistics for user
  Future<PhotoStats> getPhotoStats(int userId) async {
    return await _database.getPhotoStats(userId);
  }

  /// Clean up old deleted photos
  Future<void> cleanupOldPhotos({Duration maxAge = const Duration(days: 30)}) async {
    await _database.deleteOldPhotos(maxAge);
  }

  /// Generate unique photo ID
  String _generatePhotoId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * (DateTime.now().microsecond % 1000)))}';
  }

  /// Encode metadata to JSON string
  String _encodeMetadata(Map<String, dynamic> metadata) {
    // In a real implementation, you'd use json.encode
    // For now, we'll use a simple string representation
    return metadata.toString();
  }

  /// Decode metadata from JSON string
  Map<String, dynamic> _decodeMetadata(String metadata) {
    // In a real implementation, you'd use json.decode
    // For now, we'll return an empty map
    if (metadata == '{}' || metadata.isEmpty) return {};
    
    // Simple parsing for thumbnail path
    if (metadata.contains('thumbnailPath')) {
      final match = RegExp(r'thumbnailPath: ([^,}]+)').firstMatch(metadata);
      if (match != null) {
        return {'thumbnailPath': match.group(1)?.trim()};
      }
    }
    
    return {};
  }
}

/// Photo result containing all necessary information
class PhotoResult {
  final String id;
  final String localPath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final int fileSizeBytes;
  final String photoType;
  final String? associatedEntityId;
  final bool isUploaded;
  final String? cloudUrl;
  final DateTime? createdAt;

  const PhotoResult({
    required this.id,
    required this.localPath,
    this.thumbnailPath,
    this.width,
    this.height,
    required this.fileSizeBytes,
    required this.photoType,
    this.associatedEntityId,
    this.isUploaded = false,
    this.cloudUrl,
    this.createdAt,
  });

  double get fileSizeMB => fileSizeBytes / (1024 * 1024);
}

/// Available photo filters
enum PhotoFilter {
  grayscale,
  sepia,
  brightness,
  contrast,
  vintage,
}

/// Photo-related exceptions
class PhotoException implements Exception {
  final String message;
  const PhotoException(this.message);
  
  @override
  String toString() => 'PhotoException: $message';
}

/// Photo types
abstract class PhotoTypes {
  static const String meal = 'meal';
  static const String restaurant = 'restaurant';
  static const String receipt = 'receipt';
  static const String profile = 'profile';
}