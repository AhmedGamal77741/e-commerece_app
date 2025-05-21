import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/shop/cart_func.dart';
import 'package:ecommerece_app/features/shop/fav_fnc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetails extends StatefulWidget {
  final Product product;
  final String arrivalDay;
  final bool isSub;
  const ItemDetails({
    super.key,
    required this.product,
    required this.arrivalDay,
    String?
    itemId, // Note: itemId is declared but not used in the provided snippet
    required this.isSub,
  });

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  // late List<PricePoint> _options = widget.product.pricePoints; // Not used, can be removed

  late bool liked = false;
  @override
  void initState() {
    super.initState();
    // Ensure currentUser is not null before accessing uid
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      liked = isFavoritedByUser(p: widget.product, userId: currentUser.uid);
    }
  }

  final PageController _pageController = PageController();
  // int _currentPage = 0; // _currentPage is updated but not used elsewhere. Can be removed if not needed for other logic.

  String? _selectedOption; // Stores the selected value (index as string)

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showQuantityRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수량을 선택해주세요!'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> imageUrls = [
      if (widget.product.imgUrl != null) widget.product.imgUrl,
      ...?widget.product.imgUrls,
    ];

    final formatCurrency = NumberFormat('#,###');
    return Scaffold(
      body: ListView(
        children: [
          SizedBox(
            height: 428.h,
            child: Stack(
              children: [
                if (imageUrls.isNotEmpty)
                  PageView.builder(
                    controller: _pageController,
                    itemCount: imageUrls.length,
                    onPageChanged:
                        (index) => setState(
                          () {},
                        ), // _currentPage = index (if _currentPage is needed)
                    itemBuilder:
                        (context, index) => Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Placeholder(), // Fallback
                        ),
                  )
                else
                  const Center(
                    child: Text("No images available"),
                  ), // Handle empty image list
                // Indicator with gradient background
                if (imageUrls
                    .isNotEmpty) // Show indicator only if there are images
                  Positioned.fill(
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 60.h,
                        // decoration: BoxDecoration(), // Empty decoration, can be removed
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: imageUrls.length,
                            effect: ScrollingDotsEffect(
                              activeDotColor: Colors.black,
                              dotColor: Colors.grey,
                              dotHeight: 10.h,
                              dotWidth: 10.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!widget.isSub)
            GestureDetector(
              onTap: () {
                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser != null) {
                  _launchPaymentPage(
                    '3000', // This seems like a fixed amount
                    currentUser.uid,
                  );
                } else {
                  // Handle case where user is not logged in, e.g., show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("계속하려면 로그인해 주세요.")),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: 33.h,
                color: Colors.black,
                child: Center(
                  child: Text(
                    '프리미엄 회원 모든 제품 10% 할인',
                    style: TextStyles.abeezee16px400wW,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // spacing: 10.h, // Column doesn't have a spacing property directly. Use SizedBox.
                    children: [
                      Text(
                        widget.product.sellerName,
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 14.sp,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w400,
                          height: 1.40, // Removed .h as height is a factor
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        widget.product.productName,
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w400,
                          height: 1.40, // Removed .h
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '${widget.arrivalDay} 도착예정 - ${widget.product.freeShipping == true ? '무료 배송' : '배송료가 부과됩니다'}',
                        style: TextStyle(
                          color: const Color(0xFF747474),
                          fontSize: 14.sp,
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.w400,
                          height: 1.40, // Removed .h
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(), // Spacer is fine here
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Share functionality to be implemented
                      },
                      icon: ImageIcon(
                        const AssetImage('assets/grey_006m.png'),
                        size: 32.sp,
                        // color: liked ? Colors.black : Colors.grey, // This icon seems to be for sharing, color shouldn't depend on 'liked'
                        color: liked ? Colors.black : Colors.grey,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("즐겨찾기를 관리하려면 로그인해 주세요."),
                            ),
                          );
                          return;
                        }
                        if (liked) {
                          await removeProductFromFavorites(
                            userId: currentUser.uid,
                            productId: widget.product.product_id,
                          );
                        } else {
                          await addProductToFavorites(
                            userId: currentUser.uid,
                            productId: widget.product.product_id,
                          );
                        }
                        setState(() {
                          liked = !liked;
                        });
                      },
                      icon: ImageIcon(
                        const AssetImage(
                          'assets/grey_007m.png',
                        ), // Favorite icon
                        size: 32.sp,
                        color: liked ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12),
            child: Container(
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.27, color: Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  ...widget.product.pricePoints.asMap().entries.map((entry) {
                    int index = entry.key;
                    PricePoint pricePoint = entry.value;
                    double perUnit = pricePoint.price / pricePoint.quantity;
                    return Column(
                      children: [
                        RadioListTile<String>(
                          title: Row(
                            children: [
                              Text(
                                '${pricePoint.quantity}개 ${formatCurrency.format(widget.isSub ? pricePoint.price : (pricePoint.price / 0.9).round())}원',
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16.sp,
                                  height: 1.4, // Removed .h
                                ),
                              ),
                              SizedBox(width: 5.w), // Spacing
                              Text(
                                '(1개 ${formatCurrency.format(widget.isSub ? perUnit.round() : (perUnit / 0.9).round())}원)',
                                style: TextStyles.abeezee14px400wP600,
                              ),
                            ],
                          ),
                          value: index.toString(),
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value;
                            });
                          },
                          activeColor:
                              ColorsManager
                                  .primaryblack, // Example active color
                        ),
                        if (index < widget.product.pricePoints.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 0.27,
                            color: Color(0xFF747474),
                          ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
            child: Container(
              padding: EdgeInsets.only(
                left: 15.w,
                top: 15.h,
                bottom: 15.h,
                right: 15.w,
              ), // Added right padding
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.27, color: Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                // spacing: 10.h, // Column doesn't have a spacing property. Use SizedBox between children.
                children: [
                  _buildInfoRow('보관법 및 소비기한', widget.product.instructions),
                  SizedBox(height: 10.h),
                  const Divider(
                    height: 1,
                    thickness: 0.27,
                    color: Color(0xFF747474),
                  ),
                  SizedBox(height: 10.h),
                  _buildInfoRow(
                    '오늘출발 마감 시간',
                    '${widget.product.meridiem == 'AM' ? '오전' : '오후'} ${widget.product.baselineTime}시',
                  ),
                  SizedBox(height: 10.h),
                  const Divider(
                    height: 1,
                    thickness: 0.27,
                    color: Color(0xFF747474),
                  ),
                  SizedBox(height: 10.h),
                  _buildInfoRow(
                    '남은 수량',
                    '${widget.product.stock.toString()} 개',
                  ),
                ],
              ),
            ),
          ),
          // Padding(padding: EdgeInsets.symmetric(horizontal: 20.w)), // This empty padding does nothing
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(
          16.w,
        ), // Use .w for consistency if desired, or just 16
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("장바구니에 추가하려면 로그인해 주세요.")),
                    );
                    return;
                  }
                  if (_selectedOption == null) {
                    _showQuantityRequiredMessage();
                  } else {
                    await addProductAsNewEntryToCart(
                      userId: currentUser.uid,
                      productId: widget.product.product_id,
                      quantity:
                          widget
                              .product
                              .pricePoints[int.parse(_selectedOption!)]
                              .quantity,
                      price:
                          widget.isSub
                              ? widget
                                  .product
                                  .pricePoints[int.parse(_selectedOption!)]
                                  .price
                              : (widget
                                          .product
                                          .pricePoints[int.parse(
                                            _selectedOption!,
                                          )]
                                          .price /
                                      0.9)
                                  .round(),
                    );
                    if (mounted) {
                      // Check if the widget is still in the tree
                      Navigation(context).pop();
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: ColorsManager.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 10.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '장바구니 담기',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'NotoSans',
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w), // Use .w for consistency
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("지금 구매하려면 로그인해 주세요.")),
                    );
                    return;
                  }
                  if (_selectedOption == null) {
                    _showQuantityRequiredMessage();
                  } else {
                    await addProductAsNewEntryToCart(
                      userId: currentUser.uid,
                      productId: widget.product.product_id,
                      quantity:
                          widget
                              .product
                              .pricePoints[int.parse(_selectedOption!)]
                              .quantity,
                      price:
                          widget.isSub
                              ? widget
                                  .product
                                  .pricePoints[int.parse(_selectedOption!)]
                                  .price
                              : (widget
                                          .product
                                          .pricePoints[int.parse(
                                            _selectedOption!,
                                          )]
                                          .price /
                                      0.9)
                                  .round(),
                    );
                    if (mounted) {
                      // Check if the widget is still in the tree
                      context.go(Routes.placeOrderScreen);
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: ColorsManager.primaryblack,
                  padding: EdgeInsets.symmetric(
                    // horizontal: 0.w, // Horizontal padding 0 might make it look tight
                    vertical: 10.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '바로 구매',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NotoSans',
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to reduce repetition for info rows
  Widget _buildInfoRow(String title, String content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF121212),
            fontSize: 16.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w400,
            height: 1.40,
          ),
        ),
        SizedBox(height: 12.h / 2), // Adjust spacing as needed
        Text(
          content,
          style: TextStyle(
            color: const Color(0xFF747474),
            fontSize: 14.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w400,
            height: 1.40,
          ),
        ),
      ],
    );
  }
}

void _launchPaymentPage(String amount, String userId) async {
  final url = Uri.parse(
    'https://e-commerce-app-34fb2.web.app/payment.html?amount=$amount&userId=$userId',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      // mode: LaunchMode.externalApplication, // Consider if this is needed
    );
  } else {
    // It's good practice to give feedback to the user if launching fails.
    // This could be a SnackBar or an AlertDialog.
    // For example:
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch payment page.')));
    debugPrint('Could not launch $url'); // For debugging
    throw 'Could not launch $url';
  }
}
