import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

/// Optimized image service for better performance and caching
class OptimizedImageService {
  static final OptimizedImageService _instance = OptimizedImageService._internal();
  factory OptimizedImageService() => _instance;
  OptimizedImageService._internal();

  /// Configure cached network image with optimized settings
  static CachedNetworkImageProvider getCachedImageProvider(
    String imageUrl, {
    CacheManager? cacheManager,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      cacheManager: cacheManager ?? RestaurantAppCacheManager.instance,
    );
  }

  /// Build optimized cached network image widget
  static Widget buildOptimizedNetworkImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 200),
    bool useMemCache = true,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      memCacheWidth: width?.round(),
      memCacheHeight: height?.round(),
      cacheManager: RestaurantAppCacheManager.instance,
      placeholder: placeholder != null 
          ? (context, url) => placeholder
          : (context, url) => _buildDefaultPlaceholder(width, height),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => _buildDefaultErrorWidget(width, height),
    );
  }

  /// Build optimized restaurant image widget
  static Widget buildRestaurantImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildRestaurantPlaceholder(width, height);
    }

    return buildOptimizedNetworkImage(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: _buildRestaurantPlaceholder(width, height),
      errorWidget: _buildRestaurantPlaceholder(width, height),
    );
  }

  /// Build optimized meal photo widget
  static Widget buildMealImage(
    String? imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isNetworkImage = false,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildMealPlaceholder(width, height);
    }

    if (isNetworkImage) {
      return buildOptimizedNetworkImage(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: _buildMealPlaceholder(width, height),
        errorWidget: _buildMealPlaceholder(width, height),
      );
    }

    // Local image
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: (context, error, stackTrace) => _buildMealPlaceholder(width, height),
    );
  }

  /// Optimize image for storage and display
  static Future<OptimizedImageResult> optimizeImage(
    File imageFile, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
    ImageFormat format = ImageFormat.jpeg,
  }) async {
    try {
      // Read image
      final originalBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions maintaining aspect ratio
      final aspectRatio = originalImage.width / originalImage.height;
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxWidth) {
        newWidth = maxWidth;
        newHeight = (newWidth / aspectRatio).round();
      }

      if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (newHeight * aspectRatio).round();
      }

      // Resize image if needed
      img.Image optimizedImage = originalImage;
      if (newWidth != originalImage.width || newHeight != originalImage.height) {
        optimizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode optimized image
      late Uint8List optimizedBytes;
      switch (format) {
        case ImageFormat.jpeg:
          optimizedBytes = Uint8List.fromList(
            img.encodeJpg(optimizedImage, quality: quality),
          );
          break;
        case ImageFormat.png:
          optimizedBytes = Uint8List.fromList(
            img.encodePng(optimizedImage),
          );
          break;
        case ImageFormat.webp:
          // WebP encoding is not available in the image package by default
          // Fall back to JPEG for compatibility
          optimizedBytes = Uint8List.fromList(
            img.encodeJpg(optimizedImage, quality: quality),
          );
          break;
      }

      final compressionRatio = originalBytes.length / optimizedBytes.length;

      return OptimizedImageResult(
        optimizedBytes: optimizedBytes,
        originalSize: originalBytes.length,
        optimizedSize: optimizedBytes.length,
        compressionRatio: compressionRatio,
        width: newWidth,
        height: newHeight,
        format: format,
      );
    } catch (e) {
      throw Exception('Image optimization failed: $e');
    }
  }

  /// Create thumbnail from image
  static Future<Uint8List> createThumbnail(
    File imageFile, {
    int size = 200,
    int quality = 70,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) {
      throw Exception('Failed to decode image for thumbnail');
    }

    // Create square thumbnail
    final thumbnail = img.copyResizeCropSquare(originalImage, size: size);
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: quality));
  }

  /// Build image from memory with caching
  static Widget buildMemoryImage(
    Uint8List imageBytes, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.memory(
      imageBytes,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
    );
  }

  /// Clear image cache
  static Future<void> clearImageCache() async {
    await RestaurantAppCacheManager.instance.emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Get cache size information
  static Future<CacheInfo> getCacheInfo() async {
    // Note: Cache size info requires direct file system access
    // For now, return memory cache info only
    final memoryCacheSize = PaintingBinding.instance.imageCache.currentSizeBytes;
    final memoryCacheCount = PaintingBinding.instance.imageCache.currentSize;

    return CacheInfo(
      diskCacheSize: 0, // TODO: Implement disk cache size calculation
      memoryCacheSize: memoryCacheSize,
      memoryCacheCount: memoryCacheCount,
    );
  }

  /// Default placeholder widget
  static Widget _buildDefaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Default error widget
  static Widget _buildDefaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.error_outline,
        color: Colors.grey[600],
        size: (width != null && width < 100) ? 24 : 48,
      ),
    );
  }

  /// Restaurant placeholder
  static Widget _buildRestaurantPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.restaurant,
        color: Colors.grey[400],
        size: (width != null && width < 100) ? 32 : 64,
      ),
    );
  }

  /// Meal placeholder
  static Widget _buildMealPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.fastfood,
        color: Colors.grey[400],
        size: (width != null && width < 100) ? 32 : 64,
      ),
    );
  }
}

/// Restaurant app cache manager with optimized settings
class RestaurantAppCacheManager extends CacheManager {
  static const key = 'restaurant_app_cache';
  static RestaurantAppCacheManager? _instance;

  factory RestaurantAppCacheManager() {
    _instance ??= RestaurantAppCacheManager._();
    return _instance!;
  }

  RestaurantAppCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Images valid for 7 days
      maxNrOfCacheObjects: 200, // Maximum 200 cached images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  static RestaurantAppCacheManager get instance => RestaurantAppCacheManager();
}

/// Image optimization result
class OptimizedImageResult {
  final Uint8List optimizedBytes;
  final int originalSize;
  final int optimizedSize;
  final double compressionRatio;
  final int width;
  final int height;
  final ImageFormat format;

  const OptimizedImageResult({
    required this.optimizedBytes,
    required this.originalSize,
    required this.optimizedSize,
    required this.compressionRatio,
    required this.width,
    required this.height,
    required this.format,
  });

  /// Get size reduction percentage
  double get sizeReductionPercent => (1 - (optimizedSize / originalSize)) * 100;

  Map<String, dynamic> toJson() {
    return {
      'original_size': originalSize,
      'optimized_size': optimizedSize,
      'compression_ratio': compressionRatio,
      'size_reduction_percent': sizeReductionPercent,
      'width': width,
      'height': height,
      'format': format.name,
    };
  }
}

/// Image format enumeration
enum ImageFormat {
  jpeg,
  png,
  webp,
}

/// Cache information
class CacheInfo {
  final int diskCacheSize;
  final int memoryCacheSize;
  final int memoryCacheCount;

  const CacheInfo({
    required this.diskCacheSize,
    required this.memoryCacheSize,
    required this.memoryCacheCount,
  });

  double get diskCacheSizeMB => diskCacheSize / (1024 * 1024);
  double get memoryCacheSizeMB => memoryCacheSize / (1024 * 1024);

  Map<String, dynamic> toJson() {
    return {
      'disk_cache_size_mb': diskCacheSizeMB,
      'memory_cache_size_mb': memoryCacheSizeMB,
      'memory_cache_count': memoryCacheCount,
    };
  }
}