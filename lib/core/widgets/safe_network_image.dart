import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A thin wrapper around [CachedNetworkImage] that guards against empty URLs,
/// caches images automatically, and optimizes memory consumption using dynamic cache sizes.
class SafeNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorWidget ?? const Icon(Icons.image_not_supported);
    }

    final double devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final double logicalWidth = width ?? MediaQuery.sizeOf(context).width;
    int? cacheWidth = (logicalWidth * devicePixelRatio).round();
    int? cacheHeight =
        height != null ? (height! * devicePixelRatio).round() : null;

    // Cap the maximum physical decode size to 1080 pixels (full HD width) to prevent massive memory usage and decoding lag.
    const double maxPhysicalSize = 1080.0;
    if (cacheWidth > maxPhysicalSize) {
      if (cacheHeight != null) {
        cacheHeight = (cacheHeight * (maxPhysicalSize / cacheWidth)).round();
      }
      cacheWidth = maxPhysicalSize.round();
    }
    if (cacheHeight != null && cacheHeight > maxPhysicalSize) {
      cacheWidth = (cacheWidth * (maxPhysicalSize / cacheHeight)).round();
      cacheHeight = maxPhysicalSize.round();
    }

    // Step-align the cache sizes to the nearest 50 pixels. This creates a stable
    // cache key, preventing minor layout changes/shifts from triggering a cache miss.
    cacheWidth = ((cacheWidth + 25) ~/ 50) * 50;
    if (cacheHeight != null) {
      cacheHeight = ((cacheHeight + 25) ~/ 50) * 50;
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      imageBuilder:
          borderRadius != null
              ? (context, imageProvider) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: fit ?? BoxFit.cover,
                  ),
                ),
              )
              : null,
      placeholder: (ctx, url) => placeholder ?? const SizedBox.shrink(),
      errorWidget:
          (ctx, url, error) =>
              errorWidget ?? const Icon(Icons.image_not_supported),
    );
  }
}

/// A memory-efficient ImageProvider for network images (typically avatars or backgrounds).
/// Automatically caches the image and downsamples its decode resolution to prevent main thread lag.
ImageProvider safeNetworkImageProvider(
  String url, {
  int maxCacheWidth = 200, // Default to 200 physical pixels wide for crisp yet small avatars
  int? maxCacheHeight,
}) {
  if (url.isEmpty) {
    return const AssetImage('assets/avatar.png');
  }
  final provider = CachedNetworkImageProvider(url);
  return ResizeImage(provider, width: maxCacheWidth, height: maxCacheHeight);
}
