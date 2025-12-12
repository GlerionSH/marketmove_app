import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/services/image_service.dart';

/// A reusable widget for picking and displaying images.
/// Supports both product and expense images.
class ImagePickerCard extends StatefulWidget {
  final String? imageUrl;
  final String imageType; // 'product' or 'expense'
  final Function(Uint8List bytes, String fileName)? onImagePicked;
  final VoidCallback? onImageDeleted;
  final bool isLoading;
  final bool isCircular;
  final double size;

  const ImagePickerCard({
    super.key,
    this.imageUrl,
    required this.imageType,
    this.onImagePicked,
    this.onImageDeleted,
    this.isLoading = false,
    this.isCircular = false,
    this.size = 150,
  });

  @override
  State<ImagePickerCard> createState() => _ImagePickerCardState();
}

class _ImagePickerCardState extends State<ImagePickerCard> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    if (!_imageLoaded) {
      _imageLoaded = true;
      _fadeController.forward();
    }
  }

  Future<void> _pickImage() async {
    final result = await ImageService.pickImage();
    if (result != null && widget.onImagePicked != null) {
      widget.onImagePicked!(result.bytes, result.fileName);
    }
  }

  void _showImageOptions(BuildContext context, AppLocalizations t) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                ListTile(
                  leading: Icon(Icons.visibility, color: colorScheme.primary),
                  title: Text(t.viewImage),
                  onTap: () {
                    Navigator.pop(context);
                    _showFullImage(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: colorScheme.primary),
                  title: Text(t.changeImage),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text(t.deleteImage, style: TextStyle(color: colorScheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onImageDeleted?.call();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.add_photo_alternate, color: colorScheme.primary),
                  title: Text(t.addImage),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: colorScheme.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 200,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image, size: 64, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    final label = widget.imageType == 'product' ? t.productImage : t.expenseImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.isLoading ? null : () => _showImageOptions(context, t),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: widget.isCircular
                  ? BorderRadius.circular(widget.size / 2)
                  : BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: widget.isCircular
                  ? BorderRadius.circular(widget.size / 2)
                  : BorderRadius.circular(12),
              child: widget.isLoading
                  ? _buildLoadingState()
                  : hasImage
                      ? _buildImageState()
                      : _buildPlaceholderState(t),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.isLoading)
          TextButton.icon(
            onPressed: () => _showImageOptions(context, t),
            icon: Icon(
              hasImage ? Icons.edit : Icons.add_photo_alternate,
              size: 18,
            ),
            label: Text(hasImage ? t.changeImage : t.addImage),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.imageUploading,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageState() {
    final colorScheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            _onImageLoaded();
            return child;
          }
          return Container(
            color: colorScheme.primary.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.imageError,
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderState(AppLocalizations t) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 40,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            t.noImage,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// A smaller thumbnail widget for list items.
class ImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData placeholderIcon;
  final Color? placeholderColor;
  final bool isCircular;

  const ImageThumbnail({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.placeholderIcon = Icons.image,
    this.placeholderColor,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final color = placeholderColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasImage ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: isCircular
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: isCircular
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(8),
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: color.withOpacity(0.1),
                    child: Center(
                      child: SizedBox(
                        width: size * 0.4,
                        height: size * 0.4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: color.withOpacity(0.1),
                  child: Icon(
                    Icons.broken_image,
                    size: size * 0.5,
                    color: color.withOpacity(0.5),
                  ),
                ),
              )
            : Icon(
                placeholderIcon,
                size: size * 0.5,
                color: color,
              ),
      ),
    );
  }
}
