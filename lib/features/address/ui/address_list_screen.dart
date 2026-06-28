import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/address/domain/models/address.dart';
import 'package:ecommerece_app/features/address/domain/address_controller.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressListScreen extends ConsumerStatefulWidget {
  const AddressListScreen({super.key});

  @override
  ConsumerState<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends ConsumerState<AddressListScreen> {
  String? _processingId;

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressControllerProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 21.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '배송지 변경',
          style: TextStyle(color: Colors.black, fontSize: 16.sp),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Address Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () => _navigateToAddressForm(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black87),
                minimumSize: Size.fromHeight(48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text('배송지 추가', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
          ),

          // Address List
          Expanded(
            child: addressesAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
              error: (err, stack) => Center(child: Text('오류가 발생했습니다: $err')),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return const Center(child: Text('등록된 배송지가 없습니다'));
                }

                return ListView.separated(
                  itemCount: addresses.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final addressId = address.id;

                    return InkWell(
                      onTap: () => _selectAddress(address),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.detailAddress,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    address.address,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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
                                          address.isDefault ||
                                                  _processingId != null
                                              ? null
                                              : () async {
                                                setState(() {
                                                  _processingId = addressId;
                                                });
                                                try {
                                                  await ref
                                                      .read(
                                                        addressControllerProvider
                                                            .notifier,
                                                      )
                                                      .deleteAddress(addressId);
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _processingId = null;
                                                    });
                                                  }
                                                }
                                              },
                                      style: TextButton.styleFrom(
                                        fixedSize: Size(48.w, 30.h),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _processingId == addressId
                                              ? SizedBox(
                                                width: 14.w,
                                                height: 14.w,
                                                child:
                                                    const CircularProgressIndicator(
                                                      color: Colors.black,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : Text(
                                                '삭제',
                                                style: TextStyle(
                                                  color:
                                                      address.isDefault
                                                          ? Colors.grey
                                                          : ColorsManager
                                                              .primaryblack,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                    ),
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
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                                : TextButton(
                                  onPressed:
                                      _processingId != null
                                          ? null
                                          : () async {
                                            try {
                                              await ref.read(addressControllerProvider.notifier).setAsDefaultAddress(addressId);
                                            } catch (error) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('오류가 발생했습니다'),
                                                ),
                                              );
                                            }
                                          },
                                  style: TextButton.styleFrom(
                                    fixedSize: Size(48.w, 30.h),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.0,
                                    ),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddressForm(BuildContext context) async {
    final result = await context.pushNamed<bool>(Routes.addAddressScreen);

    if (!context.mounted) return;

    if (result == true) {
      ref.read(addressControllerProvider.notifier).refreshAddresses();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('배송지 정보가 저장되었습니다')));
    }
  }

  void _selectAddress(Address address) {
    Navigator.pop(context, address);
  }
}
