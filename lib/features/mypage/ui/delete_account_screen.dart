import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원 탈퇴', style: TextStyles.abeezee16px400wPblack),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '회원탈퇴시 기존의 모든정보는\n 즉시 파기되며 복구 할 수 없습니다',
              textAlign: TextAlign.center,
              style: TextStyles.abeezee20px400wPblack,
            ),
            verticalSpace(30),
            Container(
              decoration: ShapeDecoration(
                color: ColorsManager.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: ColorsManager.primary100),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 25.h,
                      ),
                      child: Text(
                        '탈퇴사유',
                        style: TextStyles.abeezee16px400wPblack,
                      ),
                    ),
                    Divider(color: ColorsManager.primary100),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 10,
                      minLines: 6,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "내용",
                        hintStyle: TextStyles.abeezee16px400wP600,
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return '탈퇴사유를 작성해주세요';
                        } else if (val.length > 30) {
                          return '탈퇴사유가 너무 깁니다';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            verticalSpace(50),
            WideTextButton(
              txt: '탈퇴 신청하기',
              color: ColorsManager.white,
              txtColor: ColorsManager.primaryblack,
              func: () async {
                if (!_formKey.currentState!.validate()) return;

                final confirmed = await showDeleteAccountDialog(context);
                if (confirmed) {
                  try {
                    await ref.read(profileControllerProvider).deleteAccount(
                      reason: reasonController.text.trim(),
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('탈퇴 처리가 완료되었습니다. 30일 이내에 재가입 할 수 없습니다.'),
                        ),
                      );
                      context.pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('탈퇴 처리에 실패했습니다. 다시 시도해주세요.')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showDeleteAccountDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('탈퇴 안내'),
        content: const Text('정말로 탈퇴 하시겠습니까?'),
        actions: [
          TextButton(
            child: Text('취소 ', style: TextStyles.abeezee13px400wPblack),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          BlackTextButton(
            txt: '탈퇴 하기',
            func: () async {
              Navigator.of(context).pop(true);
            },
            style: TextStyles.abeezee14px400wW,
          ),
        ],
      );
    },
  ).then((value) => value ?? false); // return false if null
}
