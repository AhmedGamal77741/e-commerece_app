import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/features/address/domain/address_controller.dart';

class AddressListItem extends ConsumerWidget {
  final Address address;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const AddressListItem({
    super.key,
    required this.address,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phone,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.detailAddress,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.address,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onEdit != null) ...[
                        TextButton(
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            fixedSize: Size(48.w, 30.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child: Text(
                            '수정',
                            style: TextStyle(
                              color: ColorsManager.primaryblack,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color:
                              address.isDefault
                                  ? Colors.grey.shade200
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TextButton(
                          onPressed:
                              address.isDefault
                                  ? null
                                  : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('삭제'),
                                          content: const Text('정말 삭제하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: const Text(
                                                '취소',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                              child: const Text(
                                                '삭제',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      try {
                                        await ref
                                            .read(
                                              addressControllerProvider.notifier,
                                            )
                                            .deleteAddress(address.id);
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('삭제 중 오류가 발생했습니다'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          style: TextButton.styleFrom(
                            fixedSize: Size(48.w, 30.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child: Text(
                            '삭제',
                            style: TextStyle(
                              color:
                                  address.isDefault
                                      ? Colors.grey
                                      : ColorsManager.primaryblack,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            (address.isDefault)
                ? Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    '기본배송지',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                )
                : TextButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(addressControllerProvider.notifier)
                          .setAsDefaultAddress(address.id);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('오류가 발생했습니다')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    fixedSize: Size(48.w, 30.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: Text(
                    '선택',
                    style: TextStyle(
                      color: ColorsManager.primaryblack,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
