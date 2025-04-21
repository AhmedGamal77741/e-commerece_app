import 'package:ecommerece_app/core/helpers/basetime.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/shop/cart_func.dart';
import 'package:ecommerece_app/features/shop/fav_fnc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ItemDetails extends StatefulWidget {
  final Map<String, dynamic> data;

  const ItemDetails({super.key, required this.data});

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  late Map<String, dynamic> productData;
  late bool liked = false;
  @override
  void initState() {
    super.initState();
    productData = widget.data;
    liked = productData['liked'] ?? false;
  }

  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedOption; // Stores the selected value

  final List<String> _options = ['Option 1', 'Option 2', 'Option 3'];
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> imageUrls = productData['imgUrls'];

    return Scaffold(
      body: ListView(
        children: [
          SizedBox(
            height: 428.h,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: imageUrls.length,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemBuilder:
                      (context, index) => Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Placeholder(), // Fallback
                      ),
                ),

                // Indicator with gradient background
                Positioned.fill(
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10.h,
                    children: [
                      Text(
                        productData['sellerName'],
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 14.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      Text(
                        productData['productName'],
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 16.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                      Text(
                        '${getArrivalDay(productData['meridiem'], productData['baselinehour'])} - ${productData['freeShipping'] == true ? '무료 배송' : '배송료가 부과됩니다'}',
                        style: TextStyle(
                          color: const Color(0xFF747474),
                          fontSize: 14.sp,
                          fontFamily: 'ABeeZee',
                          fontWeight: FontWeight.w400,
                          height: 1.40.h,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: IconButton(
                    onPressed: () {},
                    icon: ImageIcon(
                      AssetImage('assets/grey_006m.png'),
                      color: liked ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                Flexible(
                  child: IconButton(
                    onPressed:
                        liked
                            ? () async {
                              await removeProductFromFavorites(
                                userId:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '',
                                productId: productData['product_id'],
                              );
                              setState(() {
                                liked = !liked;
                              });
                            }
                            : () async {
                              await addProductToFavorites(
                                userId:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '',
                                productId: productData['product_id'],
                              );
                              setState(() {
                                liked = !liked;
                              });
                            },
                    icon: ImageIcon(
                      AssetImage('assets/grey_007m.png'),
                      color: liked ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),

              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.27, color: const Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<String>(
                        value: '1',
                        groupValue: _selectedOption,
                        onChanged:
                            (value) => setState(() => _selectedOption = value),
                      ),
                      Flexible(
                        child: Text(
                          '1 수량 ${productData['price']} KRW (1 조각 ${productData['price']})',
                        ),
                      ),
                    ],
                  ),
                  Divider(),

                  Row(
                    children: [
                      Radio<String>(
                        value: '2',
                        groupValue: _selectedOption,
                        onChanged:
                            (value) => setState(() => _selectedOption = value),
                      ),
                      Flexible(
                        child: Text(
                          '2 수량 ${productData['price']} KRW (2 조각 ${productData['price'] * 2})',
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Row(
                    children: [
                      Radio<String>(
                        value: '4',
                        groupValue: _selectedOption,
                        onChanged:
                            (value) => setState(() => _selectedOption = value),
                      ),
                      Flexible(
                        child: Text(
                          '4 수량 ${productData['price']} KRW (4 조각 ${productData['price'] * 4})',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),

            child: Container(
              padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),

              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.27, color: const Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10.h,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12.h,
                    children: [
                      Flexible(
                        child: Text(
                          '구매 안내',
                          style: TextStyle(
                            color: const Color(0xFF121212),
                            fontSize: 16.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          productData['instructions'],
                          style: TextStyle(
                            color: const Color(0xFF747474),
                            fontSize: 14.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12.h,
                    children: [
                      Flexible(
                        child: Text(
                          '오늘 배송을 시작하려면 미리 주문하세요',
                          style: TextStyle(
                            color: const Color(0xFF121212),
                            fontSize: 16.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          ' ${productData['baselinehour']} ${productData['meridiem']}',
                          style: TextStyle(
                            color: const Color(0xFF747474),
                            fontSize: 14.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12.h,
                    children: [
                      Flexible(
                        child: Text(
                          '재고 남음',
                          style: TextStyle(
                            color: const Color(0xFF121212),
                            fontSize: 16.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          productData['stock'].toString(),
                          style: TextStyle(
                            color: const Color(0xFF747474),
                            fontSize: 14.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                            height: 1.40.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),

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
                  side: BorderSide(width: 0.27, color: const Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10.h,
                children: [
                  Row(
                    children: [
                      RatingBar(
                        ignoreGestures: true,
                        itemSize: 20.sp,
                        maxRating: 5,
                        minRating: 0,
                        initialRating: 3.5,
                        allowHalfRating: true,
                        ratingWidget: RatingWidget(
                          full: Icon(
                            Icons.star,
                            color: ColorsManager.primaryblack,
                          ),
                          half: Icon(
                            Icons.star_half,
                            color: ColorsManager.primaryblack,
                          ),
                          empty: Icon(
                            Icons.star_border,
                            color: ColorsManager.primary300,
                          ),
                        ),
                        onRatingUpdate: (rating) {
                          print("평점은: $rating");
                        },
                      ),
                      Text("(1,740)", style: TextStyles.abeezee14px400wP600),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Image.asset(
                          'assets/product_image_order.png',
                          width: 105.w,
                          height: 105.h,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi interdum tincidunt nisi, sed euismod nibh viverra eu. ',
                                style: TextStyles.abeezee16px400wPblack,
                              ),

                              RatingBar(
                                ignoreGestures: true,
                                itemSize: 20.sp,
                                maxRating: 5,
                                minRating: 0,
                                initialRating: 4,
                                allowHalfRating: true,
                                ratingWidget: RatingWidget(
                                  full: Icon(
                                    Icons.star,
                                    color: ColorsManager.primaryblack,
                                  ),
                                  half: Icon(
                                    Icons.star_half,
                                    color: ColorsManager.primaryblack,
                                  ),
                                  empty: Icon(
                                    Icons.star_border,
                                    color: ColorsManager.primary300,
                                  ),
                                ),
                                onRatingUpdate: (rating) {
                                  print("Rating is: $rating");
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Image.asset(
                          'assets/product_image_order.png',
                          width: 105.w,
                          height: 105.h,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi interdum tincidunt nisi, sed euismod nibh viverra eu. ',
                                style: TextStyles.abeezee16px400wPblack,
                              ),

                              RatingBar(
                                ignoreGestures: true,
                                itemSize: 20.sp,
                                maxRating: 5,
                                minRating: 0,
                                initialRating: 4,
                                allowHalfRating: true,
                                ratingWidget: RatingWidget(
                                  full: Icon(
                                    Icons.star,
                                    color: ColorsManager.primaryblack,
                                  ),
                                  half: Icon(
                                    Icons.star_half,
                                    color: ColorsManager.primaryblack,
                                  ),
                                  empty: Icon(
                                    Icons.star_border,
                                    color: ColorsManager.primary300,
                                  ),
                                ),
                                onRatingUpdate: (rating) {
                                  print("Rating is: $rating");
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(5),
                  Text(
                    '모두 보기',
                    style: TextStyle(
                      color: const Color(0xFF747474),
                      fontSize: 14.sp,
                      fontFamily: 'ABeeZee',
                      fontWeight: FontWeight.w400,
                      height: 1.40.h,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  await addProductAsNewEntryToCart(
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    productId: productData['product_id'],
                    quantity: int.parse(_selectedOption ?? '1'),
                  );

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder:
                  //         (context) => ShoppingCart(data: {'price': price}),
                  //   ),
                  // );
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
                    side: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '장바구니에 추가',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'ABeeZee',
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: ColorsManager.primaryblack,
                  padding: EdgeInsets.symmetric(
                    horizontal: 0.w,
                    vertical: 10.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '지금 주문하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'ABeeZee',
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
}
