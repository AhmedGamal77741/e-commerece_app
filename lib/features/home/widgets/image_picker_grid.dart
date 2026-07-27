import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/add_post_notifier.dart';

class ImagePickerGrid extends ConsumerWidget {
  const ImagePickerGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(addPostNotifierProvider.select((s) => s.images));

    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160.h,
      margin: EdgeInsets.only(top: 8.h),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        onReorder: (oldIndex, newIndex) {
          ref.read(addPostNotifierProvider.notifier).reorderImages(oldIndex, newIndex);
        },
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final imageItem = images[index];

          return ListenableBuilder(
            key: ValueKey(imageItem.id),
            listenable: imageItem,
            builder: (context, child) {
              Widget imgWidget;
              if (imageItem.networkUrl != null) {
                imgWidget = Image.network(
                  imageItem.networkUrl!,
                  height: 160.h,
                  width: 120.w,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                );
              } else if (kIsWeb) {
                if (imageItem.bytes != null) {
                  imgWidget = Image.memory(
                    imageItem.bytes!,
                    height: 160.h,
                    width: 120.w,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                  );
                } else {
                  imgWidget = FutureBuilder<Uint8List>(
                    future: imageItem.localFile.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          height: 160.h,
                          width: 120.w,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }
              } else {
                imgWidget = Image.file(
                  File(imageItem.localFile.path),
                  height: 160.h,
                  width: 120.w,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                );
              }

              return Container(
                margin: EdgeInsets.only(right: 8.w),
                width: 120.w,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: imgWidget,
                    ),
                    if (imageItem.isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: imageItem.progress,
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (imageItem.hasError)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.drag_indicator,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(addPostNotifierProvider.notifier).removeImage(imageItem);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
