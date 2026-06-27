import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BuyNowAddressCard extends ConsumerWidget {
  final String uid;
  final Address address;
  final VoidCallback onSelectAddress;

  const BuyNowAddressCard({
    super.key,
    required this.uid,
    required this.address,
    required this.onSelectAddress,
  });

  Widget _buildNoAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배송지 미설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w400,
            height: 1.40.h,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '배송지를 설정해주세요',
          style: TextStyle(
            fontSize: 15.sp,
            color: const Color(0xFF9E9E9E),
            fontFamily: 'NotoSans',
          ),
        ),
      ],
    );
  }

  Widget _buildAddressText({
    required String label,
    required String name,
    required String phone,
    required String addressStr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.abeezee16px400wPblack.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        verticalSpace(5),
        Text(name, style: _greyStyle()),
        Text(phone, style: _greyStyle()),
        Text(addressStr, style: _greyStyle()),
      ],
    );
  }

  TextStyle _greyStyle() => TextStyle(
    fontSize: 15.sp,
    color: Colors.grey[800],
    fontFamily: 'NotoSans',
    fontWeight: FontWeight.w400,
    height: 1.40.h,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: address.name.isEmpty
              ? FutureBuilder<Map<String, dynamic>?>(
                  future: ref
                      .read(checkoutControllerProvider.notifier)
                      .getUserDefaultAddress(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return _buildNoAddress();
                    }
                    final d = snapshot.data!;
                    return _buildAddressText(
                      label: '배송지 정보 (기본 배송지)',
                      name: d['name'] ?? '',
                      phone: d['phone'] ?? '',
                      addressStr: d['address'] ?? '',
                    );
                  },
                )
              : _buildAddressText(
                  label: '배송지 정보 (기본 배송지)',
                  name: address.name,
                  phone: address.phone,
                  addressStr: address.detailAddress,
                ),
        ),
        IconButton(
          onPressed: onSelectAddress,
          icon: Icon(
            Icons.arrow_forward_ios_sharp,
            size: 30.r,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
