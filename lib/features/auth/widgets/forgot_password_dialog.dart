import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';

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
  ConsumerState<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
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
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        '비밀번호 찾기', 
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가입한 이메일을 입력해주세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          verticalSpace(10),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '이메일',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
          if (dialogError.isNotEmpty) ...[
            verticalSpace(10),
            Text(
              dialogError, 
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
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
          child: Text(
            '취소', 
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: authState.isLoading
              ? null
              : () async {
                  if (resetEmailController.text.isEmpty) {
                    setState(() {
                      dialogError = '이메일을 입력해주세요.';
                    });
                    return;
                  }

                  try {
                    await ref.read(authNotifierProvider.notifier).sendPasswordReset(
                      resetEmailController.text,
                    );
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
                      dialogError = e.toString().replaceAll('Exception: ', '');
                    });
                  }
                },
          child: authState.isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  '전송',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
      ],
    );
  }
}
