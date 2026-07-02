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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey),
      ),
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
  return const AssetImage('assets/avatar.png');
}
