import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/theming/colors.dart';

Future<void> showForgotPasswordDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) {
      return const ForgotPasswordDialog();
    },
  );
}

class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final resetEmailController = TextEditingController();
  String dialogError = '';

  @override
  void dispose() {
    resetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return AlertDialog(
      backgroundColor: ColorsManager.white,
      title: Text('비밀번호 찾기', style: TextStyles.abeezee16px400wPblack),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('가입한 이메일을 입력해주세요.', style: TextStyles.abeezee13px400wPblack),
          verticalSpace(10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: '이메일',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
          if (dialogError.isNotEmpty) ...[
            verticalSpace(10),
            Text(dialogError, style: TextStyles.abeezee16px400wPred),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!authState.isLoading) {
              Navigator.pop(context);
            }
          },
          child: Text('취소', style: TextStyles.abeezee14px400wP600),
        ),
        TextButton(
          onPressed:
              authState.isLoading
                  ? null
                  : () async {
                    if (resetEmailController.text.isEmpty) {
                      setState(() {
                        dialogError = '이메일을 입력해주세요.';
                      });
                      return;
                    }

                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .sendPasswordReset(resetEmailController.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('비밀번호 재설정 이메일이 전송되었습니다.'),
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        dialogError = e.toString().replaceAll(
                          'Exception: ',
                          '',
                        );
                      });
                    }
                  },
          child:
              authState.isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    '전송',
                    style: TextStyles.abeezee14px400wP600.copyWith(
                      color: ColorsManager.primaryblack,
                    ),
                  ),
        ),
      ],
    );
  }
}
