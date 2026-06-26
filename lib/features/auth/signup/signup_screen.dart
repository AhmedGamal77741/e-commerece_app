import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/widgets/profile_image_picker.dart';
import 'package:ecommerece_app/features/auth/widgets/terms_and_conditions_checkbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool agreedToTerms = false;
  bool agreedToPrivacy = false;
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  bool isPrivate = false;
  String imgUrl = '';
  String error = '';
  XFile? selectedImage;

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileImagePicker(
                    selectedImage: selectedImage,
                    onImagePicked: (image) {
                      setState(() {
                        selectedImage = image;
                      });
                    },
                  ),
                  verticalSpace(30),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '닉네임', 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '한글',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return '이름을 입력하세요';
                        } else if (val.length > 30) {
                          return '이름이 너무 깁니다';
                        }
                        return null;
                      },
                    ),
                  ),
                  verticalSpace(16),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '전화번호', 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return '전화번호를 입력하세요';
                        }
                        final koreanReg = RegExp(
                          r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
                        );
                        if (!koreanReg.hasMatch(val)) {
                          return '유효한 한국 전화번호를 입력하세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  verticalSpace(16),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '이메일', 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                  verticalSpace(16),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '비밀번호', 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      keyboardType: TextInputType.visiblePassword,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '영문, 숫자 조합 8자 이상',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                  verticalSpace(16),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '비공개 프로필', 
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CupertinoSwitch(
                          value: isPrivate,
                          onChanged: (s) {
                            setState(() {
                              isPrivate = s;
                            });
                          },
                          activeTrackColor: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            '친구로 수락한 사람만 회원님을\n구독하고 게시물을 볼수있어요.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  verticalSpace(20),
                  TermsAndConditionsCheckbox(
                    agreedToTerms: agreedToTerms,
                    agreedToPrivacy: agreedToPrivacy,
                    onChanged: (value) {
                      setState(() {
                        agreedToTerms = value;
                        agreedToPrivacy = value;
                      });
                    },
                  ),
                  if (error.isNotEmpty) ...[
                    verticalSpace(16),
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
                            if (!agreedToTerms || !agreedToPrivacy) {
                              setState(() {
                                error = '모든 약관에 동의해야 가입할 수 있습니다.';
                              });
                              return;
                            }
                            if (selectedImage == null) {
                              setState(() {
                                error = '프로필 사진을 등록해야 가입할 수 있습니다.';
                              });
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              MyUser myUser = MyUser.empty;
                              myUser.email = emailController.text;
                              myUser.name = nameController.text.trim();
                              myUser.isPrivate = isPrivate;
                              imgUrl.isEmpty
                                  ? myUser.url = "https://i.ibb.co/mrVrHy7z/avatar.png"
                                  : myUser.url = imgUrl;
                              myUser.phoneNumber = phoneController.text;

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('show_bank_prompt_after_login', true);

                              try {
                                await ref.read(authNotifierProvider.notifier).signUp(
                                  myUser,
                                  passwordController.text,
                                  selectedImage,
                                );
                                if (context.mounted) {
                                  setState(() {
                                    error = '';
                                  });
                                }
                              } catch (e) {
                                await prefs.remove('show_bank_prompt_after_login');
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
                            '가입하기',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  verticalSpace(30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
