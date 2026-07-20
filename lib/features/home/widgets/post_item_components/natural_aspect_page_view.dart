import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NaturalAspectPageView extends ConsumerStatefulWidget {
  final List imgUrls;
  final PageController pageController;
  final double? explicitWidth;
  final Map? imageRatios;

  const NaturalAspectPageView({
    super.key,
    required this.imgUrls,
    required this.pageController,
    this.explicitWidth,
    this.imageRatios,
  });

  @override
  ConsumerState<NaturalAspectPageView> createState() =>
      NaturalAspectPageViewState();
}

class NaturalAspectPageViewState extends ConsumerState<NaturalAspectPageView> {
  static final Map<String, double> _globalRatioCache = {};
  List<double?> _ratios = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.imageRatios != null) {
      widget.imageRatios!.forEach((key, value) {
        if (key is String && value is num) {
          _globalRatioCache[key] = value.toDouble();
        }
      });
    }
    _ratios = List<double?>.filled(widget.imgUrls.length, null);
    for (int i = 0; i < widget.imgUrls.length; i++) {
      final url = widget.imgUrls[i]?.toString() ?? '';
      if (url.isNotEmpty && _globalRatioCache.containsKey(url)) {
        _ratios[i] = _globalRatioCache[url];
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  void _precacheImages() {
    for (int i = 0; i < widget.imgUrls.length; i++) {
      final url = widget.imgUrls[i]?.toString() ?? '';
      if (url.isNotEmpty) {
        final provider =
            kIsWeb
                ? safeNetworkImageProvider(url)
                : CachedNetworkImageProvider(url) as ImageProvider;
        precacheImage(provider, context).catchError((_) {});

        if (_ratios[i] == null) {
          final stream = provider.resolve(ImageConfiguration.empty);
          late ImageStreamListener listener;
          listener = ImageStreamListener(
            (info, _) {
              stream.removeListener(listener);
              final ratio = info.image.width / info.image.height;
              _onRatioResolved(i, ratio);
            },
            onError: (exception, stackTrace) {
              stream.removeListener(listener);
            },
          );
          stream.addListener(listener);
        }
      }
    }
  }

  @override
  void didUpdateWidget(NaturalAspectPageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.imageRatios != null) {
      widget.imageRatios!.forEach((key, value) {
        if (key is String && value is num) {
          _globalRatioCache[key] = value.toDouble();
        }
      });
    }

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
        final url = widget.imgUrls[i]?.toString() ?? '';
        if (url.isNotEmpty && _globalRatioCache.containsKey(url)) {
          _ratios[i] = _globalRatioCache[url];
        }
      }
      _precacheImages();
    }
  }

  void _onRatioResolved(int index, double ratio) {
    if (index >= _ratios.length || _ratios[index] == ratio) return;
    final url = widget.imgUrls[index]?.toString() ?? '';
    _globalRatioCache[url] = ratio;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _ratios[index] = ratio;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.explicitWidth != null) {
      return _buildWithWidth(widget.explicitWidth!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - 20.w;
        return _buildWithWidth(availableWidth);
      },
    );
  }

  Widget _buildWithWidth(double availableWidth) {
    final int safePage =
        (_ratios.isNotEmpty && _currentPage < _ratios.length)
            ? _currentPage
            : 0;

    final double currentRatio =
        (_ratios.isNotEmpty && _ratios[safePage] != null)
            ? _ratios[safePage]!
            : 1.1;

    if (widget.imgUrls.length == 1) {
      return AspectRatio(
        aspectRatio: currentRatio,
        child: SafeNetworkImage(
          url: widget.imgUrls[0]?.toString() ?? '',
          width: availableWidth,
          height: availableWidth / currentRatio,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(25),
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          onRatioResolved: (ratio) => _onRatioResolved(0, ratio),
          placeholder: const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
          ),
          errorWidget: const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: currentRatio,
          child: SizedBox(
            width: availableWidth,
            child: PageView.builder(
              controller: widget.pageController,
              itemCount: widget.imgUrls.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) {
                if (mounted && page != _currentPage) {
                  setState(() => _currentPage = page);
                }
              },
              itemBuilder: (context, index) {
                final double ratio =
                    (index < _ratios.length && _ratios[index] != null)
                        ? _ratios[index]!
                        : 1.1;

                return KeepAliveWrapper(
                  child: AspectRatio(
                    aspectRatio: ratio,
                    child: SafeNetworkImage(
                      url: widget.imgUrls[index]?.toString() ?? '',
                      width: availableWidth,
                      height: availableWidth / ratio,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(25),
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      onRatioResolved:
                          (ratio) => _onRatioResolved(index, ratio),
                      placeholder: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                      ),
                      errorWidget: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                        child: Center(
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

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
