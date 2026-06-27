import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ItemDetailsInfoCard extends StatelessWidget {
  final Product product;

  const ItemDetailsInfoCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
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
            _buildInfoRow('배송', product.arrivalDate ?? ''),
            SizedBox(height: 10.h),
            const Divider(height: 1, thickness: 0.40, color: Color(0xFF747474)),
            SizedBox(height: 10.h),
            _buildInfoRow('보관법 및 소비기한', product.instructions),
            SizedBox(height: 10.h),
            const Divider(height: 1, thickness: 0.40, color: Color(0xFF747474)),
            SizedBox(height: 10.h),
            _buildInfoRow('남은 수량', '${product.stock.toString()} 개'),
            SizedBox(height: 10.h),
            const Divider(height: 1, thickness: 0.40, color: Color(0xFF747474)),
            SizedBox(height: 10.h),
            _buildInfoRow('제품안내', product.description ?? ''),
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
