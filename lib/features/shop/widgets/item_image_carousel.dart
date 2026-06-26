import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ItemImageCarousel extends StatefulWidget {
  final Product product;
  const ItemImageCarousel({super.key, required this.product});

  @override
  State<ItemImageCarousel> createState() => _ItemImageCarouselState();
}

class _ItemImageCarouselState extends State<ItemImageCarousel> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> imageUrls = [
      if (widget.product.imgUrl != null) widget.product.imgUrl,
      ...widget.product.imgUrls,
    ];

    return SizedBox(
      height: 428,
      child: Stack(
        children: [
          if (imageUrls.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: imageUrls.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            const Center(child: Text("No images available")),
          if (imageUrls.isNotEmpty)
            Positioned.fill(
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 60,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: imageUrls.length,
                      effect: const ScrollingDotsEffect(
                        activeDotColor: Colors.black,
                        dotColor: Colors.grey,
                        dotHeight: 10,
                        dotWidth: 10,
                      ),
                      onDotClicked: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          if (widget.product.stock == 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Image.asset(
                      'assets/sold_out.png',
                      color: Colors.black,
                      fit: BoxFit.contain,
                      cacheWidth: 600,
                      cacheHeight: 600,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 5,
            left: 5,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).goNamed(Routes.navBar);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
