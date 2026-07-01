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
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                err.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      );
    });

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
                    child: const Text('닉네임', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        hintText: '한글',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                    child: const Text('전화번호', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
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
                    child: const Text('이메일', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
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
                    child: const Text('비밀번호', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        hintText: '영문, 숫자 조합 8자 이상',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
                            color: Colors.grey,
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
                    child: const Text('비공개 프로필', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          activeTrackColor: Colors.black,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            '친구로 수락한 사람만 회원님을\n구독하고 게시물을 볼수있어요.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                  verticalSpace(20),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            if (!agreedToTerms || !agreedToPrivacy) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('모든 약관에 동의해야 가입할 수 있습니다.', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                              return;
                            }
                            if (selectedImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('프로필 사진을 등록해야 가입할 수 있습니다.', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
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

                              await ref.read(authNotifierProvider.notifier).signUp(
                                myUser,
                                passwordController.text,
                                selectedImage,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '가입하기',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
