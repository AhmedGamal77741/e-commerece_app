import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/address/ui/add_address_screen.dart';
import 'package:ecommerece_app/features/address/ui/address_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/cart/domain/bank_controller.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_form_controller.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_section_card.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_item_summary.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_address_card.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_delivery_request.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_payment_selector.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_receipt_option.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_bottom_bar.dart';
import 'package:ecommerece_app/features/cart/widgets/checkout_shared/checkout_bottom_sheets.dart';

class BuyNow extends StatelessWidget {
  final String? paymentId;
  final String? productName;
  final String? productImgUrl;

  const BuyNow({super.key, this.paymentId, this.productName, this.productImgUrl});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        checkoutFormPaymentIdProvider.overrideWithValue(paymentId),
      ],
      child: BuyNowContent(
        productName: productName,
        productImgUrl: productImgUrl,
      ),
    );
  }
}

class BuyNowContent extends ConsumerWidget {
  final String? productName;
  final String? productImgUrl;

  BuyNowContent({super.key, this.productName, this.productImgUrl});

  final _bottomSheetFormKey = GlobalKey<FormState>();
  final formatCurrency = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));

    final asyncState = ref.watch(checkoutFormControllerProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          title: const Text(
            '주문 / 결제',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: asyncState.when(
          data: (state) {
            final displayName = state.pendingBuynowData?['product_name'] as String? ?? productName ?? '';
            final displayImgUrl = state.pendingBuynowData?['imgUrl'] as String? ?? productImgUrl ?? '';
            final bankAccounts = ref.watch(bankAccountsStreamProvider).value ?? [];

            return Padding(
              padding: EdgeInsets.only(left: 15.w, top: 10.h, right: 15.w),
              child: ListView(
                children: [
                  CheckoutSectionCard(
                    child: CheckoutItemSummary(
                      displayImgUrl: displayImgUrl,
                      displayName: displayName,
                      pendingQuantity: state.pendingQuantity,
                      pendingPrice: state.pendingPrice,
                    ),
                  ),
                  verticalSpace(10),
                  CheckoutSectionCard(
                    child: CheckoutAddressCard(
                      uid: uid,
                      address: state.address,
                      onSelectAddress: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddressListScreen()),
                        );
                        if (result != null) {
                          ref.read(checkoutFormControllerProvider.notifier).setAddress(result, ref.read(checkoutFormPaymentIdProvider) ?? '');
                        }
                      },
                    ),
                  ),
                  verticalSpace(10),
                  CheckoutSectionCard(
                    child: CheckoutDeliveryRequest(
                      selectedRequest: state.selectedRequest,
                      manualRequest: state.manualRequest,
                      onManualRequestChanged: (text) {
                        ref.read(checkoutFormControllerProvider.notifier).setManualRequest(text);
                      },
                      onShowSheet: () => CheckoutBottomSheets.showDeliveryRequestSheet(context, ref),
                    ),
                  ),
                  verticalSpace(10),
                  CheckoutSectionCard(
                    child: CheckoutPaymentSelector(
                      bankAccounts: bankAccounts,
                      selectedBankIndex: state.selectedBankIndex,
                      onShowBottomSheet: () => CheckoutBottomSheets.showBankAccountBottomSheet(context, ref),
                    ),
                  ),
                  verticalSpace(10),
                  CheckoutSectionCard(
                    child: CheckoutReceiptOption(
                      selectedOption: state.selectedOption,
                      onShowBottomSheet: () => CheckoutBottomSheets.showReceiptBottomSheet(context, ref, _bottomSheetFormKey),
                    ),
                  ),
                  verticalSpace(15.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
          error: (e, st) => Center(child: Text('오류가 발생했습니다: $e')),
        ),
        bottomNavigationBar: asyncState.maybeWhen(
          data: (state) {
            final bankAccounts = ref.watch(bankAccountsStreamProvider).value ?? [];
            return CheckoutBottomBar(
              pendingPrice: state.pendingPrice,
              isProcessing: state.isProcessing,
              onValidate: () async {
                final controller = ref.read(checkoutFormControllerProvider.notifier);
                
                if (state.selectedOption != 1 && state.selectedOption != 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('현금 영수증 또는 세금 계산서를 선택해주세요'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return false;
                }
                
                if (!controller.validateReceiptTypeFields(context)) return false;
                
                if (state.address.id.isEmpty) {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                  );
                  if (result != true) {
                    return false;
                  }
                  if (!context.mounted) return false;
                  await controller.reloadAddressAndInstructions();
                  return false;
                }
                
                if (bankAccounts.isEmpty || state.selectedBankIndex < 0) {
                  CheckoutBottomSheets.showBankAccountBottomSheet(context, ref);
                  return false;
                }
                
                final payerId = bankAccounts[state.selectedBankIndex]['payerId'] as String? ?? '';
                if (payerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('계좌 정보가 올바르지 않습니다. 계좌를 다시 등록해주세요.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return false;
                }
                return true;
              },
              onSlideComplete: () {
                _showLoadingModal(context);
                ref.read(checkoutFormControllerProvider.notifier).handlePlaceOrder(
                  context: context,
                  uid: uid,
                  bankAccounts: bankAccounts,
                  onSuccess: () {
                    Navigator.of(context, rootNavigator: true).pop(); // pop loading modal
                    context.go(Routes.orderCompleteScreen);
                  },
                  onError: (msg) {
                    Navigator.of(context, rootNavigator: true).pop(); // pop loading modal
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: Colors.red),
                    );
                  },
                );
              },
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showLoadingModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.shrink(),
                  SizedBox(height: 16),
                  Text(
                    '결제 처리 중입니다...',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '잠시만 기다려 주세요',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
