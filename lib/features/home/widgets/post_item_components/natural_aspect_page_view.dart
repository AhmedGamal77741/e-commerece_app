import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// =============================================================================
// NaturalAspectPageView
// =============================================================================
class NaturalAspectPageView extends ConsumerStatefulWidget {
  final List imgUrls;
  final PageController pageController;
  final double? explicitWidth;

  const NaturalAspectPageView({
    super.key,
    required this.imgUrls,
    required this.pageController,
    this.explicitWidth,
  });

  @override
  ConsumerState<NaturalAspectPageView> createState() =>
      NaturalAspectPageViewState();
}

class NaturalAspectPageViewState extends ConsumerState<NaturalAspectPageView> {
  List<double?> _ratios = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _ratios = List<double?>.filled(widget.imgUrls.length, null);
    for (int i = 0; i < widget.imgUrls.length; i++) {
      _resolveRatio(i);
    }
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(NaturalAspectPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController.removeListener(_onPageChanged);
      widget.pageController.addListener(_onPageChanged);
    }

    // Check if the list of image URLs changed (different elements or different length)
    bool urlsChanged = widget.imgUrls.length != oldWidget.imgUrls.length;
    if (!urlsChanged) {
      for (int i = 0; i < widget.imgUrls.length; i++) {
        if (widget.imgUrls[i] != oldWidget.imgUrls[i]) {
          urlsChanged = true;
          break;
        }
      }
    }

    if (urlsChanged) {
      setState(() {
        _ratios = List<double?>.filled(widget.imgUrls.length, null);
        _currentPage = 0;
      });
      for (int i = 0; i < widget.imgUrls.length; i++) {
        _resolveRatio(i);
      }
    }
  }

  void _onPageChanged() {
    final page = widget.pageController.page?.round() ?? 0;
    if (page != _currentPage && mounted) {
      setState(() => _currentPage = page);
    }
  }

  void _resolveRatio(int index) {
    final image = NetworkImage(widget.imgUrls[index] as String);
    final stream = image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (mounted) {
          setState(() {
            if (index < _ratios.length) {
              _ratios[index] =
                  info.image.width.toDouble() / info.image.height.toDouble();
            }
          });
        }
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (mounted) {
          setState(() {
            if (index < _ratios.length) {
              _ratios[index] = 1.0;
            }
          });
        }
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    // If explicitWidth is provided, bypass LayoutBuilder completely.
    if (widget.explicitWidth != null) {
      debugPrint(
        '✅ NaturalAspectPageView using explicitWidth=${widget.explicitWidth}',
      );
      return _buildWithWidth(widget.explicitWidth!);
    }

    debugPrint('⚠️ NaturalAspectPageView falling back to LayoutBuilder');
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width - 20.w;
        return _buildWithWidth(availableWidth);
      },
    );
  }

  Widget _buildWithWidth(double availableWidth) {
    debugPrint(
      '🟢 _buildWithWidth availableWidth=$availableWidth  ratio=${_ratios.isNotEmpty ? _ratios[0] : "empty"}',
    );

    final int safePage =
        (_ratios.isNotEmpty && _currentPage < _ratios.length)
            ? _currentPage
            : 0;

    final double? currentRatio = _ratios.isNotEmpty ? _ratios[safePage] : null;

    if (currentRatio == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: availableWidth,
          height: availableWidth * 0.75,
          color: Colors.grey[200],
        ),
      );
    }

    final double currentHeight = availableWidth / currentRatio;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: availableWidth,
          height: currentHeight,
          child: PageView.builder(
            controller: widget.pageController,
            itemCount: widget.imgUrls.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final double? ratio =
                  index < _ratios.length ? _ratios[index] : null;

              if (ratio == null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: availableWidth,
                    height: currentHeight,
                    color: Colors.grey[200],
                  ),
                );
              }

              final double itemHeight = availableWidth / ratio;

              return ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SizedBox(
                  width: availableWidth,
                  height: itemHeight,
                  child: CachedNetworkImage(
                    imageUrl: widget.imgUrls[index] as String,
                    width: availableWidth,
                    height: itemHeight,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder:
                        (context, url) => Container(
                          width: availableWidth,
                          height: itemHeight,
                          color: Colors.grey[200],
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          width: availableWidth,
                          height: itemHeight,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.imgUrls.length > 1)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: SmoothPageIndicator(
              controller: widget.pageController,
              count: widget.imgUrls.length,
              effect: const ScrollingDotsEffect(
                activeDotColor: Colors.black,
                dotColor: Colors.grey,
                dotHeight: 8,
                dotWidth: 8,
                paintStyle: PaintingStyle.fill,
              ),
              onDotClicked: (index) {
                widget.pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
      ],
    );
  }
}
