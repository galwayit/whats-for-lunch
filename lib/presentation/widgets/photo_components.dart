import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/photo_service.dart';
import '../providers/photo_providers.dart';
import 'ux_components.dart';

/// Photo capture widget with camera and gallery options
class PhotoCaptureWidget extends ConsumerStatefulWidget {
  final int userId;
  final String photoType;
  final String? associatedEntityId;
  final ValueChanged<List<PhotoResult>>? onPhotosSelected;
  final int maxPhotos;
  final bool allowMultiple;
  final String? customLabel;

  const PhotoCaptureWidget({
    super.key,
    required this.userId,
    required this.photoType,
    this.associatedEntityId,
    this.onPhotosSelected,
    this.maxPhotos = 5,
    this.allowMultiple = true,
    this.customLabel,
  });

  @override
  ConsumerState<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends ConsumerState<PhotoCaptureWidget> {
  List<PhotoResult> _selectedPhotos = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UXCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Text(
                widget.customLabel ?? 'Add Photos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_selectedPhotos.isNotEmpty)
                Chip(
                  label: Text('${_selectedPhotos.length}'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingM),

          // Photo action buttons
          if (_selectedPhotos.isEmpty || widget.allowMultiple) ...[
            Row(
              children: [
                Expanded(
                  child: UXSecondaryButton(
                    onPressed: _isLoading ? null : _takePhoto,
                    text: 'Take Photo',
                    icon: Icons.camera_alt,
                  ),
                ),
                const SizedBox(width: UXComponents.paddingM),
                Expanded(
                  child: UXSecondaryButton(
                    onPressed: _isLoading ? null : (widget.allowMultiple ? _selectMultiplePhotos : _selectPhoto),
                    text: widget.allowMultiple ? 'Select Photos' : 'Choose Photo',
                    icon: Icons.photo_library,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingM),
          ],

          // Loading indicator
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(UXComponents.paddingL),
                child: CircularProgressIndicator(),
              ),
            ),
          ],

          // Selected photos preview
          if (_selectedPhotos.isNotEmpty) ...[
            PhotoPreviewGrid(
              photos: _selectedPhotos,
              onPhotoTap: _showPhotoDetail,
              onPhotoRemove: _removePhoto,
              showRemoveButton: true,
            ),
          ],

          // Helper text
          if (_selectedPhotos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: UXComponents.paddingS),
              child: Text(
                widget.allowMultiple 
                  ? 'Add up to ${widget.maxPhotos} photos to capture your experience'
                  : 'Add a photo to enhance your entry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= widget.maxPhotos) {
      _showMaxPhotosReached();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoService = PhotoService(ref.read(databaseProvider));
      final result = await photoService.takePhoto(
        userId: widget.userId,
        photoType: widget.photoType,
        associatedEntityId: widget.associatedEntityId,
      );

      if (result != null) {
        setState(() {
          _selectedPhotos.add(result);
        });
        widget.onPhotosSelected?.call(_selectedPhotos);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Failed to take photo: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPhoto() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photoService = PhotoService(ref.read(databaseProvider));
      final result = await photoService.selectFromGallery(
        userId: widget.userId,
        photoType: widget.photoType,
        associatedEntityId: widget.associatedEntityId,
      );

      if (result != null) {
        setState(() {
          _selectedPhotos = [result]; // Replace for single photo mode
        });
        widget.onPhotosSelected?.call(_selectedPhotos);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Failed to select photo: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectMultiplePhotos() async {
    final remainingSlots = widget.maxPhotos - _selectedPhotos.length;
    if (remainingSlots <= 0) {
      _showMaxPhotosReached();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoService = PhotoService(ref.read(databaseProvider));
      final results = await photoService.selectMultipleFromGallery(
        userId: widget.userId,
        photoType: widget.photoType,
        associatedEntityId: widget.associatedEntityId,
        maxImages: remainingSlots,
      );

      if (results.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(results);
        });
        widget.onPhotosSelected?.call(_selectedPhotos);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Failed to select photos: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removePhoto(PhotoResult photo) {
    setState(() {
      _selectedPhotos.removeWhere((p) => p.id == photo.id);
    });
    widget.onPhotosSelected?.call(_selectedPhotos);
    HapticFeedback.lightImpact();
  }

  void _showPhotoDetail(PhotoResult photo) {
    showDialog(
      context: context,
      builder: (context) => PhotoDetailDialog(photo: photo),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMaxPhotosReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum of ${widget.maxPhotos} photos allowed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Grid display for photo previews
class PhotoPreviewGrid extends StatelessWidget {
  final List<PhotoResult> photos;
  final ValueChanged<PhotoResult>? onPhotoTap;
  final ValueChanged<PhotoResult>? onPhotoRemove;
  final bool showRemoveButton;
  final int crossAxisCount;

  const PhotoPreviewGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
    this.onPhotoRemove,
    this.showRemoveButton = false,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: UXComponents.paddingS,
        mainAxisSpacing: UXComponents.paddingS,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return PhotoPreviewTile(
          photo: photo,
          onTap: onPhotoTap,
          onRemove: showRemoveButton ? onPhotoRemove : null,
        );
      },
    );
  }
}

/// Individual photo preview tile
class PhotoPreviewTile extends StatelessWidget {
  final PhotoResult photo;
  final ValueChanged<PhotoResult>? onTap;
  final ValueChanged<PhotoResult>? onRemove;

  const PhotoPreviewTile({
    super.key,
    required this.photo,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onTap?.call(photo),
      child: Stack(
        children: [
          // Photo image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UXComponents.borderRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(UXComponents.borderRadius),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _buildPhotoImage(context),
              ),
            ),
          ),

          // Remove button
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove?.call(photo),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

          // Upload status indicator
          if (!photo.isUploaded)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Local',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoImage(BuildContext context) {
    // Use thumbnail if available, otherwise full image
    final imagePath = photo.thumbnailPath ?? photo.localPath;

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

/// Photo detail dialog for full view
class PhotoDetailDialog extends StatefulWidget {
  final PhotoResult photo;

  const PhotoDetailDialog({
    super.key,
    required this.photo,
  });

  @override
  State<PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<PhotoDetailDialog> {
  bool _showInfo = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Photo image
          GestureDetector(
            onTap: () {
              setState(() {
                _showInfo = !_showInfo;
              });
            },
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UXComponents.borderRadius),
                child: Image.file(
                  File(widget.photo.localPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Info overlay
          if (_showInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(UXComponents.borderRadius),
                    bottomRight: Radius.circular(UXComponents.borderRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Photo Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Size', '${widget.photo.fileSizeMB.toStringAsFixed(2)} MB'),
                    if (widget.photo.width != null && widget.photo.height != null)
                      _buildInfoRow('Dimensions', '${widget.photo.width} × ${widget.photo.height}'),
                    _buildInfoRow('Type', widget.photo.photoType),
                    if (widget.photo.createdAt != null)
                      _buildInfoRow('Created', _formatDate(widget.photo.createdAt!)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Photo gallery widget for displaying collections
class PhotoGalleryWidget extends StatelessWidget {
  final List<PhotoResult> photos;
  final String? title;
  final VoidCallback? onAddPhoto;
  final bool showAddButton;

  const PhotoGalleryWidget({
    super.key,
    required this.photos,
    this.title,
    this.onAddPhoto,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (title != null || showAddButton)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingL),
            child: Row(
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Spacer(),
                if (showAddButton)
                  IconButton(
                    onPressed: onAddPhoto,
                    icon: const Icon(Icons.add_photo_alternate),
                    tooltip: 'Add Photo',
                  ),
              ],
            ),
          ),

        const SizedBox(height: UXComponents.paddingS),

        // Photos
        if (photos.isEmpty)
          _buildEmptyState(context)
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingL),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < photos.length - 1 ? UXComponents.paddingS : 0,
                  ),
                  child: SizedBox(
                    width: 120,
                    child: PhotoPreviewTile(
                      photo: photo,
                      onTap: (photo) => _showPhotoDetail(context, photo),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingL),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(UXComponents.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No photos yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(BuildContext context, PhotoResult photo) {
    showDialog(
      context: context,
      builder: (context) => PhotoDetailDialog(photo: photo),
    );
  }
}

