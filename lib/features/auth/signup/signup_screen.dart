import 'dart:io';

import 'package:ecommerece_app/core/helpers/loading_dialog.dart';
import 'package:ecommerece_app/core/helpers/loading_service.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  bool signUpRequired = false;
  String imgUrl = '';
  String error = '';
  final fireBaseRepo = FirebaseUserRepo();
  XFile? selectedImage;

  Future<void> pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          selectedImage = image;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
            child: Column(
              children: [
                Container(
                  decoration: ShapeDecoration(
                    color: ColorsManager.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: ColorsManager.primary100,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 20.h,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '닉네임',
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                              Spacer(),
                              InkWell(
                                onTap: () async {
                                  await pickImage(); // Just pick, don't upload
                                },
                                child:
                                    selectedImage != null
                                        ? ClipOval(
                                          child: Image.file(
                                            File(selectedImage!.path),
                                            height: 55.h,
                                            width: 56.w,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : Image.asset(
                                          'assets/avatar.png',
                                          height: 55.h,
                                          width: 56.w,
                                        ),
                              ),
                            ],
                          ),
                          UnderlineTextField(
                            controller: nameController,
                            hintText: '팽이마켓',
                            obscureText: false,
                            keyboardType: TextInputType.name,
                            validator: (val) {
                              if (val!.isEmpty) {
                                return '이름을 입력하세요';
                              } else if (val.length > 30) {
                                return '이름이 너무 깁니다';
                              }
                              return null;
                            },
                          ),

                          verticalSpace(20),
                          Text('전화번호', style: TextStyles.abeezee16px400wPblack),
                          verticalSpace(8),
                          UnderlineTextField(
                            controller: phoneController,
                            hintText: '전화번호를 입력하세요',
                            obscureText: false,
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return '전화번호를 입력하세요';
                              }
                              // Korean phone number: 010-xxxx-xxxx or 010xxxxxxxx
                              final koreanReg = RegExp(
                                r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
                              );
                              if (!koreanReg.hasMatch(val)) {
                                return '유효한 한국 전화번호를 입력하세요';
                              }
                              return null;
                            },
                          ),
                          verticalSpace(20),
                          Text('이메일', style: TextStyles.abeezee16px400wPblack),
                          verticalSpace(8),
                          UnderlineTextField(
                            controller: emailController,
                            hintText: '이메일을 입력하세요',
                            obscureText: false,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val!.isEmpty) {
                                return '이 필드를 작성해 주세요';
                              } else if (!RegExp(
                                r'^[\w-\.]+@([\w-]+.)+[\w-]{2,4}$',
                              ).hasMatch(val)) {
                                return '유효한 이메일을 입력해 주세요';
                              }
                              return null;
                            },
                          ),
                          verticalSpace(20),
                          Text('비밀번호', style: TextStyles.abeezee16px400wPblack),
                          verticalSpace(8),
                          UnderlineTextField(
                            controller: passwordController,
                            hintText: '영문,숫자 조합 8자 이상',
                            obscureText: obscurePassword,
                            keyboardType: TextInputType.visiblePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            validator: (val) {
                              if (val!.isEmpty) {
                                return '이 필드를 작성해 주세요';
                              } else if (!RegExp(
                                r'^(?=.*[A-Za-z])(?=.*\d).{8,}$',
                              ).hasMatch(val)) {
                                return '유효한 비밀번호를 입력해 주세요';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                verticalSpace(30),
                Text(error, style: TextStyles.abeezee16px400wPred),

                // Container(
                //   decoration: ShapeDecoration(
                //     color: ColorsManager.white,
                //     shape: RoundedRectangleBorder(
                //       side: BorderSide(width: 1, color: ColorsManager.primary100),
                //       borderRadius: BorderRadius.circular(25),
                //     ),
                //   ),
                //   child: Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text('월 회비', style: TextStyles.abeezee16px400wPblack),
                //         Text('3,000원', style: TextStyles.abeezee14px400wP600),
                //         Divider(color: ColorsManager.primary100),
                //         Text('혜택', style: TextStyles.abeezee16px400wPblack),
                //         Text(
                //           '전제품 무료배송, 무료반품 , 멤버십 커뮤니티 이용, 최저가 \n 상품 구매 ',
                //           style: TextStyles.abeezee14px400wP600,
                //         ),
                //         Divider(color: ColorsManager.primary100),
                //         Text('결제', style: TextStyles.abeezee16px400wPblack),
                //         UnderlineTextField(
                //           controller: paymentInfoController,
                //           hintText: '결제수단 등록',
                //           obscureText: false,
                //           keyboardType: TextInputType.name,
                //         ),
                //         /* Text('결제 정보를 입력하세요', style: TextStyles.abeezee14px400wP600), */
                //       ],
                //     ),
                //   ),
                // ),
                WideTextButton(
                  txt: '가입하기',
                  func: () async {
                    if (_formKey.currentState!.validate()) {
                      LoadingService().showLoading();

                      MyUser myUser = MyUser.empty;
                      myUser.email = emailController.text;
                      myUser.name = nameController.text;
                      imgUrl.isEmpty
                          ? myUser.url = "https://i.ibb.co/ccfDzhyH/avatar.png"
                          : myUser.url = imgUrl;
                      myUser.phoneNumber = phoneController.text;
                      var result = await fireBaseRepo.signUp(
                        myUser,
                        passwordController.text,
                        selectedImage,
                      );
                      LoadingService().hideLoading();

                      if (result != '회원가입이 완료되었습니다') {
                        setState(() {
                          error = result;
                        });
                      }
                    }
                  },
                  color: ColorsManager.primaryblack,
                  txtColor: ColorsManager.white,
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: LoadingService().isLoading,
          builder: (context, isLoading, child) {
            return isLoading
                ? Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                )
                : SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
