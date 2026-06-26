import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/no_account_screen.dart';
import 'package:ecommerece_app/core/widgets/receipt_setup_screen.dart';
// import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/cart/domain/cart_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/shop/widgets/item_image_carousel.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart'; // NEW UI
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart'; // NEW UI
import 'package:ecommerece_app/features/home/widgets/share_dialog.dart'; // NEW UI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MERGE NOTES:
//   UI     → Branch Y  (Stack body with floating chat button, showShareDialog,
//                       responsive banner padding, bare Padding on bottomNav)
//   Logic  → Branch X  (pending_buynow write, paymentId generation, SafeArea
//                       on bottomNavigationBar for system nav bar protection)
//   Added  → imgUrl field in pending_buynow write (requested)
// ─────────────────────────────────────────────────────────────────────────────

class ItemDetails extends ConsumerStatefulWidget {
  final Product product;
  final String arrivalDay;
  final bool isSub;
  const ItemDetails({
    super.key,
    required this.product,
    required this.arrivalDay,
    String? itemId,
    required this.isSub,
  });

  @override
  ConsumerState<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends ConsumerState<ItemDetails> {
  // NEW UI: chat service for floating seller chat button
  

  late bool liked = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser != null) {
      liked = widget.product.favBy.contains(currentUser.uid);
    }

    final defaultIndex = widget.product.pricePoints.indexWhere(
      (pricePoint) => pricePoint.quantity == 1,
    );
    if (defaultIndex != -1) {
      _selectedOption = defaultIndex.toString();
    } else if (widget.product.pricePoints.isNotEmpty) {
      _selectedOption = '0';
    }
  }

  final PageController _pageController = PageController();
  String? _selectedOption;

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

  // ── NEW LOGIC: write pending_buynow to Firestore then navigate ─────────────
  Future<void> _handleBuyNow({
    required String uid,
    required bool isSub,
    required PricePoint pricePoint,
    required int currentStock,
  }) async {
    final paymentId = await ref.read(cartControllerProvider).processBuyNow(
      product: widget.product,
      pricePoint: pricePoint,
      pricePointIndex: int.parse(_selectedOption!),
      isSub: isSub,
    );

    if (paymentId != null && mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      context.go('/buy-now?paymentId=$paymentId');
    }
  }

  // ── Shared stock + cart check used by both buttons ─────────────────────────
  Future<int?> _getValidatedStock(PricePoint pricePoint) async {
    final currentStock = await ref.read(cartControllerProvider).getValidatedStock(
      widget.product.product_id,
      pricePoint.quantity,
    );
    if (currentStock == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수량 부족'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
    return currentStock;
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###');
    final currentUser = ref.watch(authStateProvider).value;

    // ── Not logged in scaffold ─────────────────────────────────────────────
    if (currentUser == null) {
      return Scaffold(
        body: ListView(
          children: [
            ItemImageCarousel(product: widget.product),
            Container(
              width: double.infinity,
              height: 500.h,
              color: Colors.black,
              child: Center(child: ShiningPremiumBanner()),
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
                      children: [
                        Text(
                          widget.product.sellerName,
                          style: const TextStyle(
                            color: Color(0xFF121212),
                            fontSize: 14,
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w400,
                            height: 1.40,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.productName,
                          style: const TextStyle(
                            color: Color(0xFF121212),
                            fontSize: 16,
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w400,
                            height: 1.40,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.stock == 0
                              ? '품절'
                              : widget.product.arrivalDate ?? '',
                          style: const TextStyle(
                            color: Color(0xFF747474),
                            fontSize: 14,
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w400,
                            height: 1.40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          final url =
                              'https://www.pang2chocolate.com/product/${widget.product.product_id}';
                          showShareDialog(
                            context,
                            'product',
                            url,
                            widget.product.product_id,
                            widget.product.productName,
                            widget.product.imgUrl.toString(),
                            widget.product.toMap(),
                          );
                        },
                        icon: const ImageIcon(
                          AssetImage('assets/grey_006m.png'),
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: const ImageIcon(
                          AssetImage('assets/grey_007m.png'),
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildPricePointsCard(formatCurrency: formatCurrency, isSub: false),
            _buildInfoCard(),
          ],
        ),
        // NEW LOGIC: SafeArea protects against system nav bar overlap
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(child: _buildCartButton(isLoggedIn: false)),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildBuyNowButton(isLoggedIn: false, isSub: false),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Logged-in scaffold ─────────────────────────────────────────────────
    final isSub = ref.watch(isSubscribedProvider).value ?? widget.isSub;

    return Scaffold(
          body: Stack(
            children: [
              // NEW UI: ListView inside Stack to allow floating chat button
              ListView(
                children: [
                  ItemImageCarousel(product: widget.product),
                  if (!isSub)
                    Container(
                      width: double.infinity,
                      height: 500.h,
                      color: Colors.black,
                      child: Center(child: ShiningPremiumBanner()),
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
                            children: [
                              Text(
                                widget.product.sellerName,
                                style: TextStyle(
                                  color: const Color(0xFF121212),
                                  fontSize: 14.sp,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40,
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
                                  height: 1.40,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                widget.product.stock == 0
                                    ? '품절'
                                    : widget.product.arrivalDate ?? '',
                                style: TextStyle(
                                  color: const Color(0xFF747474),
                                  fontSize: 14.sp,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            // NEW UI: showShareDialog instead of ShareService
                            IconButton(
                              onPressed: () {
                                final url =
                                    'https://www.pang2chocolate.com/product/${widget.product.product_id}';
                                showShareDialog(
                                  context,
                                  'product',
                                  url,
                                  widget.product.product_id,
                                  widget.product.productName,
                                  widget.product.imgUrl.toString(),
                                  widget.product.toMap(),
                                );
                              },
                              icon: ImageIcon(
                                const AssetImage('assets/grey_006m.png'),
                                size: 32.sp,
                                color: liked ? Colors.black : Colors.grey,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final wasLiked = liked;
                                setState(() => liked = !liked);

                                try {
                                  if (wasLiked) {
                                    await ref.read(cartControllerProvider).removeFavItemByProductId(
                                      widget.product.product_id,
                                    );
                                  } else {
                                    await ref.read(cartControllerProvider).addFavItem(
                                      widget.product.product_id,
                                    );
                                  }
                                } catch (e) {
                                  setState(() => liked = wasLiked);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '요청을 처리하는 동안 오류가 발생했습니다. 다시 시도해주세요.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: ImageIcon(
                                liked
                                    ? AssetImage('assets/black_007m.png')
                                    : const AssetImage('assets/grey_007m.png'),
                                size: 32.sp,
                                color: liked ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildPricePointsCard(
                    formatCurrency: formatCurrency,
                    isSub: isSub,
                  ),
                  _buildInfoCard(),
                ],
              ),

              // NEW UI: floating chat with seller button
              Positioned(
                right: 0.w,
                bottom: -10.h,
                child: IconButton(
                  onPressed: () async {
                    try {
                      final returnList = await ref.read(chatControllerProvider)
                          .createDirectChatRoomWithSeller(
                            widget.product.deliveryManagerId.toString(),
                          );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                chatRoomId: returnList[0],
                                chatRoomName: returnList[1],
                              ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  icon: Image.asset(
                    'assets/chat_with_seller.png',
                    width: 50.w,
                    height: 50.h,
                  ),
                ),
              ),
            ],
          ),

          // NEW LOGIC: SafeArea protects against system nav bar overlap (Android + iOS)
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCartButton(
                      isLoggedIn: true,
                      uid: currentUser.uid,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildBuyNowButton(
                      isLoggedIn: true,
                      isSub: isSub,
                      uid: currentUser.uid,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  // ── Bottom button builders ─────────────────────────────────────────────────

  Widget _buildCartButton({required bool isLoggedIn, String? uid}) {
    return TextButton(
      onPressed: () async {
        if (!isLoggedIn || uid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다")),
          );
          return;
        }
        if (_selectedOption == null) {
          _showQuantityRequiredMessage();
          return;
        }
        final pricePoint =
            widget.product.pricePoints[int.parse(_selectedOption!)];
        final currentStock = await _getValidatedStock(pricePoint);
        if (currentStock == null) return;

        final cartTotalQuantity = await ref.read(cartControllerProvider).getCartItemQuantity(widget.product.product_id);

        if (cartTotalQuantity + pricePoint.quantity > currentStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '해당 상품의 남은 수량은 ${currentStock - cartTotalQuantity}개 입니다.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await ref.read(cartControllerProvider).addToCart(
          productId: widget.product.product_id,
          pricePointIndex: int.parse(_selectedOption!),
          deliveryManagerId: widget.product.deliveryManagerId ?? '',
          productName: widget.product.productName,
        );
        if (mounted) Navigation(context).pop();
      },
      style: TextButton.styleFrom(
        backgroundColor: ColorsManager.white,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
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
    );
  }

  Widget _buildBuyNowButton({
    required bool isLoggedIn,
    required bool isSub,
    String? uid,
  }) {
    return TextButton(
      onPressed: () async {
        if (!isLoggedIn || uid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다")),
          );
          return;
        }
        if (_selectedOption == null) {
          _showQuantityRequiredMessage();
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
        );

        try {
          final pricePoint =
              widget.product.pricePoints[int.parse(_selectedOption!)];
          final currentStock = await _getValidatedStock(pricePoint);
          if (currentStock == null) {
            if (mounted) Navigator.pop(context); // Dismiss loading
            return;
          }

          // NEW LOGIC: write pending_buynow then navigate with paymentId
          await _handleBuyNow(
            uid: uid,
            isSub: isSub,
            pricePoint: pricePoint,
            currentStock: currentStock,
          );
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Dismiss loading
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
          }
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: ColorsManager.primaryblack,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        '바로 구매',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'NotoSans',
          fontSize: 18.sp,
        ),
      ),
    );
  }

  // ── Reusable card builders ─────────────────────────────────────────────────

  Widget _buildPricePointsCard({
    required NumberFormat formatCurrency,
    required bool isSub,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
              final index = entry.key;
              final pricePoint = entry.value;
              final perUnit = pricePoint.price / pricePoint.quantity;
              final perUnitN = (pricePoint.price / 0.8) / pricePoint.quantity;

              return Column(
                children: [
                  RadioListTile<String>(
                    title:
                        isSub
                            ? Row(
                              children: [
                                Text(
                                  '${pricePoint.quantity}개 ${formatCurrency.format(pricePoint.price)}원',
                                  style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16.sp,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  '(1개 ${formatCurrency.format(perUnit.round())}원)',
                                  style: TextStyles.abeezee14px400wP600,
                                ),
                              ],
                            )
                            : Row(
                              children: [
                                Text(
                                  '${pricePoint.quantity}개 ',
                                  style: TextStyle(
                                    fontFamily: 'NotoSans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 18.sp,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '일반가 ${formatCurrency.format((pricePoint.price / 0.8).round())} 원',
                                          style: TextStyle(
                                            fontFamily: 'NotoSans',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16.sp,
                                            height: 1.4,
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        Text(
                                          '(1개 ${formatCurrency.format(perUnitN.round())}원)',
                                          style: TextStyles.abeezee14px400wP600,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      color: Colors.black,
                                      child: Row(
                                        children: [
                                          Text(
                                            '멤버십 ${formatCurrency.format(pricePoint.price)} 원',
                                            style: TextStyle(
                                              fontFamily: 'NotoSans',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16.sp,
                                              height: 1.4,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            '(1개 ${formatCurrency.format(perUnit.round())}원)',
                                            style: TextStyles
                                                .abeezee14px400wP600
                                                .copyWith(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    value: index.toString(),
                    groupValue: _selectedOption,
                    onChanged:
                        (value) => setState(() => _selectedOption = value),
                    activeColor: ColorsManager.primaryblack,
                  ),
                  if (index < widget.product.pricePoints.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.40,
                      color: Color(0xFF747474),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      child: Container(
        padding: EdgeInsets.only(
          left: 15.w,
          top: 15.h,
          bottom: 15.h,
          right: 15.w,
        ),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 0.27, color: Color(0xFF747474)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('배송', widget.product.arrivalDate ?? ''),
            SizedBox(height: 10.h),
            const Divider(height: 1, thickness: 0.40, color: Color(0xFF747474)),
            SizedBox(height: 10.h),
            _buildInfoRow('보관법 및 소비기한', widget.product.instructions),
            SizedBox(height: 10.h),
            const Divider(height: 1, thickness: 0.40, color: Color(0xFF747474)),
            SizedBox(height: 10.h),
            _buildInfoRow('남은 수량', '${widget.product.stock.toString()} 개'),
            SizedBox(height: 10.h),
            const Divider(height: 1, thickness: 0.40, color: Color(0xFF747474)),
            SizedBox(height: 10.h),
            _buildInfoRow('제품안내', widget.product.description ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        SizedBox(height: 12.h / 2),
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

// ─────────────────────────────────────────────────────────────────────────────

class ShiningPremiumBanner extends ConsumerStatefulWidget {
  const ShiningPremiumBanner({super.key});

  @override
  ConsumerState<ShiningPremiumBanner> createState() => _ShiningPremiumBannerState();
}

class _ShiningPremiumBannerState extends ConsumerState<ShiningPremiumBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w, // NEW UI: responsive padding
        vertical: 30.h, // NEW UI: responsive padding
      ),
      child: Column(
        children: [
          Container(
            decoration: ShapeDecoration(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 2, color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  verticalSpace(15),
                  Text(
                    '멤버십 혜택',
                    style: TextStyles.abeezee30px800wW.copyWith(
                      fontFamily: 'ABeeZee',
                    ),
                  ),
                  verticalSpace(50),
                  Text(
                    '월회비 8,000원\n모든 제품 20% 할인',
                    textAlign: TextAlign.center,
                    style: TextStyles.abeezee18px400wPblack.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  verticalSpace(50),
                  Text(
                    '매월 5만원 이상 구매하시는 분은 멤버십 가입을 권합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyles.abeezee18px400wPblack.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          verticalSpace(15),
          TextButton(
            onPressed: () {
              final currentUser = ref.read(authStateProvider).value;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다")),
                );
                return;
              }
              _navigateToSubscriptionFromBanner(context, ref, currentUser.uid);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: WidgetStateProperty.all(Size(double.infinity, 80.h)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  side: const BorderSide(color: Colors.black, width: 0.6),
                ),
              ),
            ),
            child: Text(
              '멤버십 가입하기',
              style: TextStyles.abeezee23px800wW.copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _navigateToSubscriptionFromBanner(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  // ── Gate 1: bank account ────────────────────────────────────────────
  final firestore = ref.read(firestoreProvider);
  final userDoc = await firestore.collection('users').doc(uid).get();
  final data = userDoc.data();

  final accounts = data?['bankAccounts'];
  final hasBankAccount =
      accounts != null && accounts is List && accounts.isNotEmpty;

  if (!hasBankAccount) {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NoBankAccountScreen(source: 'sub'),
      ),
    );
    final refreshed = await firestore.collection('users').doc(uid).get();
    final refreshedAccounts = refreshed.data()?['bankAccounts'];
    final nowHasAccount =
        refreshedAccounts != null &&
        refreshedAccounts is List &&
        refreshedAccounts.isNotEmpty;
    if (!nowHasAccount) return;
  }

  // ── Gate 2: receipt / invoice data ──────────────────────────────────
  final cacheDoc =
      await firestore
          .collection('usercached_values')
          .doc(uid)
          .get();
  final cacheData = cacheDoc.data();
  final hasReceiptData =
      cacheData != null &&
      (cacheData['selectedOption'] == 1 || cacheData['selectedOption'] == 2) &&
      (cacheData['name'] as String? ?? '').isNotEmpty &&
      (cacheData['email'] as String? ?? '').isNotEmpty &&
      (cacheData['phone'] as String? ?? '').isNotEmpty;

  if (!hasReceiptData) {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ReceiptSetupScreen(source: 'sub'),
      ),
    );
    if (result != true) return;
  }

  // ── All gates passed ─────────────────────────────────────────────────
  if (context.mounted) {
    context.push(Routes.subscriptionScreen);
  }
}
