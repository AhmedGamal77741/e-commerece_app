import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/widgets/forgot_password_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  bool obsecurepassword = true;
  final _formKey = GlobalKey<FormState>();
  String error = '';

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: emailController,
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
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return '이 필드를 작성해 주세요';
                    } else if (!RegExp(
                      r'^[\w-\.]+@([\w-]+.)+[\w-]{2,4}$',
                    ).hasMatch(val)) {
                      return '유효한 이메일을 입력해 주세요';
                    }
                    return null;
                  },
                ),
              ),
              verticalSpace(12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: obsecurepassword,
                  keyboardType: TextInputType.visiblePassword,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '영어, 숫자 조합',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obsecurepassword = !obsecurepassword;
                        });
                      },
                      icon: Icon(
                        obsecurepassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return '이 필드를 작성해 주세요';
                    } else if (!RegExp(
                      r'^(?=.*[A-Za-z])(?=.*\d).{8,}$',
                    ).hasMatch(val)) {
                      return '유효한 비밀번호를 입력해 주세요';
                    }
                    return null;
                  },
                ),
              ),
              if (error.isNotEmpty) ...[
                verticalSpace(12),
                Text(
                  error, 
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              verticalSpace(20),
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await ref.read(authNotifierProvider.notifier).signIn(
                                  emailController.text,
                                  passwordController.text,
                                );
                            if (context.mounted) {
                              setState(() {
                                error = '';
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                error = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: authState.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '로그인',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              verticalSpace(16),
              Center(
                child: TextButton(
                  onPressed: () {
                    showForgotPasswordDialog(context);
                  },
                  child: Text(
                    '비밀번호 찾기',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
