import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:handy_app/features/requests/domain/request_image.dart';
import 'package:image_picker/image_picker.dart';

class RequestImagePicker extends StatelessWidget {
  const RequestImagePicker({
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
    this.enabled = true,
    this.maxImages = 3,
    super.key,
  });

  final List<XFile> images;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final bool enabled;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    final canAddMore = enabled && images.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'صور المشكلة (اختياري)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${images.length}/$maxImages',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'أضف حتى $maxImages صور توضّح المشكلة وتساعد الصنايعي يفهم الطلب.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (images.isNotEmpty)
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _SelectedImageTile(
                  image: images[index],
                  enabled: enabled,
                  onRemove: () => onRemoveImage(index),
                );
              },
            ),
          ),
        if (images.isNotEmpty) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: canAddMore ? onPickImages : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(canAddMore ? 'إضافة صور' : 'تم الوصول للحد الأقصى'),
        ),
      ],
    );
  }
}

class _SelectedImageTile extends StatelessWidget {
  const _SelectedImageTile({
    required this.image,
    required this.enabled,
    required this.onRemove,
  });

  final XFile image;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FutureBuilder<Uint8List>(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  width: 108,
                  height: 108,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              return Image.memory(
                snapshot.data!,
                width: 108,
                height: 108,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        if (enabled)
          Positioned(
            top: -8,
            left: -8,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
      ],
    );
  }
}

class RequestImagesGallery extends StatelessWidget {
  const RequestImagesGallery({
    required this.images,
    this.emptyMessage = 'لا توجد صور مرفقة.',
    super.key,
  });

  final List<RequestImage> images;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Text(
        emptyMessage,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final image = images[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _openPreview(context, image.url),
              child: Image.network(
                image.url,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('تعذر تحميل الصورة.'),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
