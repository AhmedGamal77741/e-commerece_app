import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter/material.dart';

class PlaceOrder extends StatefulWidget {
  const PlaceOrder({super.key});

  @override
  State<PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends State<PlaceOrder> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: Text("Place Order", style: TextStyle(fontFamily: 'ABeeZee')),
        ),
        body: Padding(
          padding: EdgeInsets.only(left: 15.w, top: 20.h, right: 15.w),
          child: ListView(
            children: [
              Container(
                padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),

                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.27,
                      color: const Color(0xFF747474),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16.h,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12.h,
                      children: [
                        Flexible(
                          child: Text(
                            'Delivery Address',
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
                            'Default Address: ',
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
                            'Delivery Instructions',
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
                            'In front of the door',
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
                            'Payment',
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
                            'Naver Pay (Quick Payment)',
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
                            'Cash Receipt',
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
                            'Cash Receipt Infomation',
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
              verticalSpace(20),
              Container(
                padding: EdgeInsets.only(left: 15.w, top: 15.h, bottom: 15.h),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.27,
                      color: const Color(0xFF747474),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16.h,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12.h,
                      children: [
                        Flexible(
                          child: Text(
                            'Order details',
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
                            'Dark Chocolates / option: 3 pieces / Quantity: 2 pieces',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w400,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '24,000 KRW',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w600,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12.h,
                      children: [
                        Flexible(
                          child: Text(
                            'Dark Chocolates / option: 1 pieces / Quantity: 1 pieces',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w400,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '4,000 KRW',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w600,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12.h,
                      children: [
                        Flexible(
                          child: Text(
                            'Dark Chocolates / option: 2 pieces / Quantity: 2 pieces',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w400,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '16,000 KRW',
                            style: TextStyle(
                              color: const Color(0xFF747474),
                              fontSize: 14.sp,
                              fontFamily: 'ABeeZee',
                              fontWeight: FontWeight.w600,
                              height: 1.40.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpace(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total : ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontFamily: 'ABeeZee',
                      fontWeight: FontWeight.w400,
                      height: 1.40.h,
                    ),
                  ),
                  Text(
                    '44,000KRW',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontFamily: 'ABeeZee',
                      fontWeight: FontWeight.w400,
                      height: 1.40.h,
                    ),
                  ),
                ],
              ),
              verticalSpace(20),

              TextButton(
                onPressed: () {
                  context.pushReplacementNamed(Routes.orderCompleteScreen);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF121212), // Background color
                  foregroundColor: Colors.white, // Text color
                  padding: EdgeInsets.zero, // Remove default padding
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0xFF121212),
                    ), // Border
                    borderRadius: BorderRadius.circular(8), // Corner radius
                  ),
                  elevation: 0, // Remove shadow
                ),
                child: Text(
                  'Place Order',
                  style: TextStyle(
                    color: const Color(0xFFF5F5F5),
                    fontSize: 18.sp,
                    fontFamily: 'ABeeZee',
                    fontWeight: FontWeight.w400,
                    height: 1.40.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
