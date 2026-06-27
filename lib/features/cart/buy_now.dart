import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
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
                      onShowSheet: () => _showDeliveryRequestSheet(context, ref),
                    ),
                  ),
                  verticalSpace(10),
                  CheckoutSectionCard(
                    child: CheckoutPaymentSelector(
                      bankAccounts: bankAccounts,
                      selectedBankIndex: state.selectedBankIndex,
                      onShowBottomSheet: () => _showBankAccountBottomSheet(context, ref, uid, bankAccounts),
                    ),
                  ),
                  verticalSpace(10),
                  CheckoutSectionCard(
                    child: CheckoutReceiptOption(
                      selectedOption: state.selectedOption,
                      onShowBottomSheet: () => _showReceiptBottomSheet(context, ref),
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
                  _showBankAccountBottomSheet(context, ref, uid, bankAccounts);
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

  void _showDeliveryRequestSheet(BuildContext context, WidgetRef ref) {
    final controller = ref.read(checkoutFormControllerProvider.notifier);
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controller.deliveryRequests
                .map(
                  (request) => ListTile(
                    title: Text(
                      request,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      controller.setSelectedRequest(request);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _showBankAccountBottomSheet(BuildContext context, WidgetRef ref, String uid, List<Map<String, dynamic>> bankAccounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(checkoutFormControllerProvider).value;
            final controller = ref.read(checkoutFormControllerProvider.notifier);
            final currentBankAccounts = ref.watch(bankAccountsStreamProvider).value ?? [];

            return Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '계좌 선택',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  verticalSpace(16),
                  if (currentBankAccounts.isEmpty)
                    const Text(
                      '등록된 계좌가 없습니다.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ...currentBankAccounts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final bank = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.account_balance,
                            color: Colors.black,
                          ),
                          title: Text(
                            "${bank['bankName']} (${bank['bankNum']})",
                            style: const TextStyle(color: Colors.black),
                          ),
                          tileColor: idx == state?.selectedBankIndex ? Colors.black12 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            controller.setSelectedBankIndex(idx);
                            Navigator.of(context).pop();
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.black,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('계좌 삭제'),
                                  content: Text(
                                    "${bank['bankName']} (${bank['bankNum']}) 계좌를 삭제하시겠습니까?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.black,
                                      ),
                                      child: const Text(
                                        '삭제',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              await controller.deleteBankAccount(bank['payerId'] as String);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        verticalSpace(5),
                      ],
                    );
                  }),
                  verticalSpace(8),
                  WideTextButton(
                    txt: '새 계좌 등록하기',
                    func: () {
                      Navigator.of(context).pop();
                      controller.launchBankRegistration();
                    },
                    color: Colors.black,
                    txtColor: Colors.white,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiptBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(checkoutFormControllerProvider).value;
            final controller = ref.read(checkoutFormControllerProvider.notifier);
            if (state == null) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(
                top: 20.h,
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _bottomSheetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRadioOption(
                            value: 1,
                            label: '현금 영수증',
                            currentValue: state.selectedOption,
                            onChanged: (v) => controller.setSelectedOption(v),
                          ),
                          _buildRadioOption(
                            value: 2,
                            label: '세금 계산서',
                            currentValue: state.selectedOption,
                            onChanged: (v) => controller.setSelectedOption(v),
                          ),
                        ],
                      ),
                      if (state.selectedOption == 1)
                        ..._buildCashReceiptFields(controller)
                      else
                        ..._buildTaxInvoiceFields(controller, state.invoiceeType),
                      verticalSpace(10),
                      WideTextButton(
                        txt: '저장',
                        func: () async {
                          if (!_bottomSheetFormKey.currentState!.validate()) return;
                          final success = await controller.saveCachedUserValues();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('정보가 저장되었습니다'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('저장 실패'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        color: Colors.black,
                        txtColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption({
    required int value,
    required String label,
    required int currentValue,
    required Function(int) onChanged,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: 20.sp / 15,
          child: Radio<int>(
            value: value,
            groupValue: currentValue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 20.sp,
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w800,
            color: ColorsManager.primaryblack,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCashReceiptFields(CheckoutFormController controller) => [
        UnderlineTextField(
          controller: controller.nameController,
          hintText: '이름',
          obscureText: false,
          keyboardType: TextInputType.text,
          validator: (val) => (val == null || val.trim().isEmpty) ? '이름을 입력해주세요' : null,
          onChanged: (_) => null,
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          controller: controller.emailController,
          hintText: '이메일',
          obscureText: false,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요';
            if (!RegExp(r'^.+@.+\..+$').hasMatch(val.trim())) {
              return '유효한 이메일을 입력해주세요';
            }
            return null;
          },
          onChanged: (_) => null,
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          controller: controller.phoneController,
          hintText: '전화번호',
          obscureText: false,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '전화번호를 입력해주세요';
            if (!RegExp(
              r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
            ).hasMatch(val)) {
              return '유효한 한국 전화번호를 입력하세요';
            }
            return null;
          },
          onChanged: (_) => null,
        ),
      ];

  List<Widget> _buildTaxInvoiceFields(CheckoutFormController controller, String invoiceeType) => [
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          value: invoiceeType,
          items: ['사업자', '개인', '외국인']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) {
            controller.setInvoiceeType(val ?? '사업자');
          },
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          obscureText: false,
          controller: controller.invoiceeCorpNumController,
          hintText: '공급받는자 사업자번호',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '사업자번호를 입력해주세요';
            final cleaned = val.trim().replaceAll('-', '');
            if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
              return '사업자번호는 숫자만 입력 가능합니다';
            }
            if (cleaned.length != 10) {
              return '사업자번호는 숫자 10자리여야 합니다 (예: 123-45-67890)';
            }
            return null;
          },
          onChanged: (_) => null,
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          obscureText: false,
          controller: controller.invoiceeCorpNameController,
          hintText: '공급받는자 상호',
          keyboardType: TextInputType.text,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '이름을 입력해주세요';
            if (val.trim().length > 200) return '입력은 최대 200자까지 가능합니다';
            return null;
          },
          onChanged: (_) => null,
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          obscureText: false,
          controller: controller.invoiceeCEONameController,
          hintText: '공급받는자 대표자 성명',
          keyboardType: TextInputType.text,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '대표자 성명을 입력해주세요';
            if (val.trim().length > 200) return '입력은 최대 200자까지 가능합니다';
            return null;
          },
          onChanged: (_) => null,
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          controller: controller.emailController,
          hintText: '이메일',
          obscureText: false,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '이메일을 입력해주세요';
            if (!RegExp(r'^.+@.+\..+$').hasMatch(val.trim())) {
              return '유효한 이메일을 입력해주세요';
            }
            return null;
          },
          onChanged: (_) => null,
        ),
        SizedBox(height: 10.h),
        UnderlineTextField(
          controller: controller.phoneController,
          hintText: '전화번호',
          obscureText: false,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '전화번호를 입력해주세요';
            if (!RegExp(
              r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
            ).hasMatch(val)) {
              return '유효한 한국 전화번호를 입력하세요';
            }
            return null;
          },
          onChanged: (_) => null,
        ),
      ];
}
