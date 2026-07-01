import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';

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
  static final Map<String, double> _globalRatioCache = {};
  final Set<String> _resolvingUrls = {};
  List<double?> _ratios = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _ratios = List<double?>.filled(widget.imgUrls.length, null);
    for (int i = 0; i < widget.imgUrls.length; i++) {
      final url = widget.imgUrls[i] as String;
      if (_globalRatioCache.containsKey(url)) {
        _ratios[i] = _globalRatioCache[url];
      }
    }
    _resolveRatiosIfNeeded();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(NaturalAspectPageView oldWidget) {
    super.didUpdateWidget(oldWidget);

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
        final url = widget.imgUrls[i] as String;
        if (_globalRatioCache.containsKey(url)) {
          _ratios[i] = _globalRatioCache[url];
        }
      }
      _resolveRatiosIfNeeded();
    }
  }

  void _resolveRatiosIfNeeded() {
    for (int i = 0; i < widget.imgUrls.length; i++) {
      if (i == 0 || (i - _currentPage).abs() <= 1) {
        final url = widget.imgUrls[i] as String;
        if (!_globalRatioCache.containsKey(url) && !_resolvingUrls.contains(url)) {
          _resolvingUrls.add(url);
          _resolveRatio(i);
        }
      }
    }
  }

  void _resolveRatio(int index) {
    final url = widget.imgUrls[index] as String;
    final image = ResizeImage(CachedNetworkImageProvider(url), width: 300);
    final stream = image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        stream.removeListener(listener);
        _resolvingUrls.remove(url);
        final ratio = info.image.width.toDouble() / info.image.height.toDouble();
        _globalRatioCache[url] = ratio;
        if (synchronousCall) {
          _ratios[index] = ratio;
        } else {
          if (mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  if (index < _ratios.length) _ratios[index] = ratio;
                });
              }
            });
          }
        }
      },
      onError: (exception, stackTrace) {
        stream.removeListener(listener);
        _resolvingUrls.remove(url);
        _globalRatioCache[url] = 1.0;
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                if (index < _ratios.length) _ratios[index] = 1.0;
              });
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
      return _buildWithWidth(widget.explicitWidth!);
    }

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
    final int safePage =
        (_ratios.isNotEmpty && _currentPage < _ratios.length)
            ? _currentPage
            : 0;

    final double? currentRatio = _ratios.isNotEmpty ? _ratios[safePage] : null;

    if (currentRatio == null) {
      return Container(
        width: availableWidth,
        height: availableWidth * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(25),
        ),
      );
    }

    final double currentHeight = availableWidth / currentRatio;

    // SHORT-CIRCUIT: If only 1 image exists, render the Image widget directly
    // and bypass PageView entirely to avoid horizontal gesture/scroll contention.
    if (widget.imgUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.hardEdge,
        child: SafeNetworkImage(
          url: widget.imgUrls[0] as String,
          width: availableWidth,
          height: currentHeight,
          fit: BoxFit.cover,
          placeholder: Container(
            width: availableWidth,
            height: currentHeight,
            color: const Color(0xFFEEEEEE),
          ),
          errorWidget: Container(
            width: availableWidth,
            height: currentHeight,
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
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          width: availableWidth,
          height: currentHeight,
          child: PageView.builder(
            controller: widget.pageController,
            itemCount: widget.imgUrls.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (page) {
              if (mounted && page != _currentPage) {
                setState(() => _currentPage = page);
                _resolveRatiosIfNeeded();
              }
            },
            itemBuilder: (context, index) {
              final double? ratio =
                  index < _ratios.length ? _ratios[index] : null;

              if (ratio == null) {
                return Container(
                  width: availableWidth,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(25),
                  ),
                );
              }

              final double itemHeight = availableWidth / ratio;

              return ClipRRect(
                borderRadius: BorderRadius.circular(25),
                clipBehavior: Clip.hardEdge,
                child: SafeNetworkImage(
                  url: widget.imgUrls[index] as String,
                  width: availableWidth,
                  height: itemHeight,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: availableWidth,
                    height: itemHeight,
                    color: const Color(0xFFEEEEEE),
                  ),
                  errorWidget: Container(
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
