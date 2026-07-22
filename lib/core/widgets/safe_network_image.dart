import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerece_app/core/helpers/error_logger.dart';

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
  final Function(double ratio)? onRatioResolved;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.onRatioResolved,
    this.fadeInDuration,
    this.fadeOutDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorWidget ?? const Icon(Icons.image_not_supported);
    }

    if (kIsWeb) {
      final imageProvider = NetworkImage(
        url,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      );
      if (onRatioResolved != null) {
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, _) {
            stream.removeListener(listener);
            final ratio = info.image.width / info.image.height;
            onRatioResolved!(ratio);
          },
          onError: (exception, stackTrace) {
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
      }

      Widget imageWidget = Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          ErrorLogger.logImageError(
            url: url,
            error: error,
            stackTrace: stackTrace,
          );
          return errorWidget ?? const Icon(Icons.image_not_supported);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const SizedBox.shrink();
        },
      );

      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
      }
      return imageWidget;
    }

    final double devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final double logicalWidth = width ?? MediaQuery.sizeOf(context).width;
    int cacheWidth = (logicalWidth * devicePixelRatio).round();
    int cacheHeight =
        height != null
            ? (height! * devicePixelRatio).round()
            : (MediaQuery.sizeOf(context).height * devicePixelRatio).round();

    // Cap the maximum physical decode size to 1080x1920 (Full HD bounds) to prevent
    // massive memory usage and decoding lag on extremely tall or uncompressed images.
    const double maxPhysicalWidth = 1080.0;
    const double maxPhysicalHeight = 1920.0;

    if (cacheWidth > maxPhysicalWidth) {
      cacheHeight = (cacheHeight * (maxPhysicalWidth / cacheWidth)).round();
      cacheWidth = maxPhysicalWidth.round();
    }
    if (cacheHeight > maxPhysicalHeight) {
      cacheWidth = (cacheWidth * (maxPhysicalHeight / cacheHeight)).round();
      cacheHeight = maxPhysicalHeight.round();
    }

    // Step-align the cache sizes to the nearest 50 pixels. This creates a stable
    // cache key, preventing minor layout changes/shifts from triggering a cache miss.
    cacheWidth = ((cacheWidth + 25) ~/ 50) * 50;
    cacheHeight = ((cacheHeight + 25) ~/ 50) * 50;

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 0),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 0),
      imageBuilder: (context, imageProvider) {
        if (onRatioResolved != null) {
          final stream = imageProvider.resolve(ImageConfiguration.empty);
          late ImageStreamListener listener;
          listener = ImageStreamListener((info, _) {
            stream.removeListener(listener);
            final ratio = info.image.width / info.image.height;
            onRatioResolved!(ratio);
          });
          stream.addListener(listener);
        }

        if (borderRadius != null) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              image: DecorationImage(
                image: imageProvider,
                fit: fit ?? BoxFit.cover,
              ),
            ),
          );
        }

        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
      },
      placeholder: (ctx, url) => placeholder ?? const SizedBox.shrink(),
      errorWidget: (ctx, url, error) {
        ErrorLogger.logImageError(url: url, error: error);
        return errorWidget ?? const Icon(Icons.image_not_supported);
      },
    );
  }
}

/// A memory-efficient ImageProvider for network images (typically avatars or backgrounds).
/// Automatically caches the image and downsamples its decode resolution to prevent main thread lag.
ImageProvider safeNetworkImageProvider(
  String url, {
  int maxCacheWidth =
      200, // Default to 200 physical pixels wide for crisp yet small avatars
  int? maxCacheHeight,
}) {
  if (url.isEmpty) {
    return const AssetImage('assets/avatar.png');
  }
  if (kIsWeb) {
    return NetworkImage(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    );
  }
  final provider = CachedNetworkImageProvider(url);
  return ResizeImage(provider, width: maxCacheWidth, height: maxCacheHeight);
}
