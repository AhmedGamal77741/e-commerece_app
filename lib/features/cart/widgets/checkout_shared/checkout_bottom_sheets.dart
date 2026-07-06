// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/cart/domain/bank_controller.dart';
import 'package:ecommerece_app/features/cart/domain/checkout_form_controller.dart';

class CheckoutBottomSheets {
  static void showDeliveryRequestSheet(BuildContext context, WidgetRef ref) {
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

  static void showBankAccountBottomSheet(BuildContext context, WidgetRef ref) {
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

  static void showReceiptBottomSheet(BuildContext context, WidgetRef ref, GlobalKey<FormState> formKey) {
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
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ..._buildCashReceiptFields(controller),
                      verticalSpace(10),
                      WideTextButton(
                        txt: '저장',
                        func: () async {
                          if (!formKey.currentState!.validate()) return;
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

  static Widget _buildRadioOption({
    required int value,
    required String label,
    required int currentValue,
    required Function(int) onChanged,
  }) {
    return RadioMenuButton<int>(
      value: value,
      groupValue: currentValue,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 20.sp,
          fontFamily: 'NotoSans',
          fontWeight: FontWeight.w800,
          color: ColorsManager.primaryblack,
        ),
      ),
    );
  }

  static List<Widget> _buildCashReceiptFields(CheckoutFormController controller) => [
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

  static List<Widget> _buildTaxInvoiceFields(CheckoutFormController controller, String invoiceeType) => [
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          initialValue: invoiceeType,
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
