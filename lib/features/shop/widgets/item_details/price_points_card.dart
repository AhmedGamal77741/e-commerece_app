import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class PricePointsCard extends StatelessWidget {
  final Product product;
  final String? selectedOption;
  final ValueChanged<String?> onChanged;
  final bool isSub;
  final NumberFormat formatCurrency;

  const PricePointsCard({
    super.key,
    required this.product,
    required this.selectedOption,
    required this.onChanged,
    required this.isSub,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
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
        child: RadioGroup<String>(
          groupValue: selectedOption,
          onChanged: onChanged,
          child: Column(
            children: [
              ...product.pricePoints.asMap().entries.map((entry) {
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            style:
                                                TextStyles.abeezee14px400wP600,
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
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      value: index.toString(),
                      activeColor: ColorsManager.primaryblack,
                    ),
                    if (index < product.pricePoints.length - 1)
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
      ),
    );
  }
}
