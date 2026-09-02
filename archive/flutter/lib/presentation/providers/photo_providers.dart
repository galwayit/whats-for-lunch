import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../services/photo_service.dart';

/// Provider for PhotoService instance
final photoServiceProvider = Provider<PhotoService>((ref) {
  final database = ref.watch(databaseProvider);
  return PhotoService(database);
});

/// Provider for database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for user photos
final userPhotosProvider = FutureProvider.family<List<PhotoResult>, int>((ref, userId) async {
  final photoService = ref.watch(photoServiceProvider);
  return await photoService.getUserPhotos(userId);
});

/// Provider for meal photos
final mealPhotosProvider = FutureProvider.family<List<PhotoResult>, String>((ref, mealId) async {
  final photoService = ref.watch(photoServiceProvider);
  return await photoService.getPhotosByMealId(mealId);
});

/// Provider for restaurant photos
final restaurantPhotosProvider = FutureProvider.family<List<PhotoResult>, String>((ref, restaurantId) async {
  final photoService = ref.watch(photoServiceProvider);
  return await photoService.getPhotosByRestaurantId(restaurantId);
});

/// Provider for photo statistics
final photoStatsProvider = FutureProvider.family<PhotoStats, int>((ref, userId) async {
  final photoService = ref.watch(photoServiceProvider);
  return await photoService.getPhotoStats(userId);
});

/// Photo management state
class PhotoManagementState {
  final List<PhotoResult> selectedPhotos;
  final bool isLoading;
  final String? errorMessage;

  const PhotoManagementState({
    this.selectedPhotos = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PhotoManagementState copyWith({
    List<PhotoResult>? selectedPhotos,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PhotoManagementState(
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Photo management notifier
class PhotoManagementNotifier extends StateNotifier<PhotoManagementState> {
  final PhotoService _photoService;

  PhotoManagementNotifier(this._photoService) : super(const PhotoManagementState());

  /// Add photos to selection
  void addPhotos(List<PhotoResult> photos) {
    state = state.copyWith(
      selectedPhotos: [...state.selectedPhotos, ...photos],
    );
  }

  /// Remove photo from selection
  void removePhoto(String photoId) {
    state = state.copyWith(
      selectedPhotos: state.selectedPhotos.where((p) => p.id != photoId).toList(),
    );
  }

  /// Clear all selected photos
  void clearPhotos() {
    state = state.copyWith(
      selectedPhotos: [],
    );
  }

  /// Take photo with camera
  Future<PhotoResult?> takePhoto({
    required int userId,
    required String photoType,
    String? associatedEntityId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _photoService.takePhoto(
        userId: userId,
        photoType: photoType,
        associatedEntityId: associatedEntityId,
      );

      if (result != null) {
        state = state.copyWith(
          selectedPhotos: [...state.selectedPhotos, result],
        );
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Select photo from gallery
  Future<PhotoResult?> selectFromGallery({
    required int userId,
    required String photoType,
    String? associatedEntityId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _photoService.selectFromGallery(
        userId: userId,
        photoType: photoType,
        associatedEntityId: associatedEntityId,
      );

      if (result != null) {
        state = state.copyWith(
          selectedPhotos: [...state.selectedPhotos, result],
        );
      }

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Select multiple photos from gallery
  Future<List<PhotoResult>> selectMultipleFromGallery({
    required int userId,
    required String photoType,
    String? associatedEntityId,
    int maxImages = 5,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _photoService.selectMultipleFromGallery(
        userId: userId,
        photoType: photoType,
        associatedEntityId: associatedEntityId,
        maxImages: maxImages,
      );

      state = state.copyWith(
        selectedPhotos: [...state.selectedPhotos, ...results],
        isLoading: false,
      );

      return results;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(String photoId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _photoService.deletePhoto(photoId);
      
      if (success) {
        state = state.copyWith(
          selectedPhotos: state.selectedPhotos.where((p) => p.id != photoId).toList(),
        );
      }

      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Apply filter to photo
  Future<PhotoResult?> applyFilter(String photoId, PhotoFilter filter) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _photoService.applyFilter(photoId, filter);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for photo management
final photoManagementProvider = StateNotifierProvider<PhotoManagementNotifier, PhotoManagementState>((ref) {
  final photoService = ref.watch(photoServiceProvider);
  return PhotoManagementNotifier(photoService);
});

/// Provider for specific photo by ID
final photoByIdProvider = FutureProvider.family<PhotoResult?, String>((ref, photoId) async {
  final photoService = ref.watch(photoServiceProvider);
  return await photoService.getPhotoById(photoId);
});

/// Provider to watch photo changes (for invalidating caches)
final photoWatcherProvider = Provider.family<void, String>((ref, photoId) {
  // This provider can be used to watch for changes to specific photos
  // and invalidate related providers when needed
  return;
});

/// Helper provider to invalidate photo-related providers when photos change
void invalidatePhotoProviders(WidgetRef ref, {int? userId, String? mealId, String? restaurantId}) {
  if (userId != null) {
    ref.invalidate(userPhotosProvider(userId));
    ref.invalidate(photoStatsProvider(userId));
  }
  if (mealId != null) {
    ref.invalidate(mealPhotosProvider(mealId));
  }
  if (restaurantId != null) {
    ref.invalidate(restaurantPhotosProvider(restaurantId));
  }
}

/// Extension for easy photo provider invalidation
extension PhotoProviderInvalidation on WidgetRef {
  void invalidatePhotoProviders({int? userId, String? mealId, String? restaurantId}) {
    if (userId != null) {
      invalidate(userPhotosProvider(userId));
      invalidate(photoStatsProvider(userId));
    }
    if (mealId != null) {
      invalidate(mealPhotosProvider(mealId));
    }
    if (restaurantId != null) {
      invalidate(restaurantPhotosProvider(restaurantId));
    }
  }
}