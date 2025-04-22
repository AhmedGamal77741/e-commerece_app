import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  IconData iconPassword = Icons.visibility;
  bool obscurePassword = true;
  bool signUpRequired = false;
  String imgUrl = '';
  String error = '';
  final fireBaseRepo = FirebaseUserRepo();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        child: Column(
          children: [
            Container(
              decoration: ShapeDecoration(
                color: ColorsManager.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: ColorsManager.primary100),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('닉네임', style: TextStyles.abeezee16px400wPblack),
                          Spacer(),
                          InkWell(
                            onTap: () async {
                              imgUrl = await uploadImageToImgBB();
                              setState(() {});
                            },
                            child:
                                imgUrl.isEmpty
                                    ? Image.asset(
                                      'assets/mypage_avatar.png',
                                      height: 55.h,
                                      width: 56.w,
                                    )
                                    : ClipOval(
                                      child: Image.network(
                                        imgUrl,
                                        height: 55.h,
                                        width: 56.w,
                                        fit:
                                            BoxFit
                                                .cover, // Ensures proper filling
                                      ),
                                    ),
                          ),
                        ],
                      ),
                      UnderlineTextField(
                        controller: nameController,
                        hintText: '이름을 입력하세요',
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
                      Text('이메일', style: TextStyles.abeezee16px400wPblack),
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
                      UnderlineTextField(
                        controller: passwordController,
                        hintText: '영문, 숫자 포함 8자 이상',
                        obscureText: obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                              if (obscurePassword) {
                                iconPassword = Icons.visibility_off;
                              } else {
                                iconPassword = Icons.visibility;
                              }
                            });
                          },
                          icon: Icon(iconPassword),
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
            Container(
              decoration: ShapeDecoration(
                color: ColorsManager.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: ColorsManager.primary100),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('월간 구독', style: TextStyles.abeezee16px400wPblack),
                    Text('3,000 KRW', style: TextStyles.abeezee14px400wP600),
                    Divider(color: ColorsManager.primary100),
                    Text('Benefits', style: TextStyles.abeezee16px400wPblack),
                    Text(
                      '모든 제품 무료 배송, 무료 반품,\n회원 커뮤니티, 최저가 보장 ',
                      style: TextStyles.abeezee14px400wP600,
                    ),
                    Divider(color: ColorsManager.primary100),
                    Text('결제', style: TextStyles.abeezee16px400wPblack),
                    Text('결제 정보를 입력하세요', style: TextStyles.abeezee14px400wP600),
                    Divider(color: ColorsManager.primary100),
                  ],
                ),
              ),
            ),
            verticalSpace(40),
            WideTextButton(
              txt: '가입하기',
              func: () async {
                if (_formKey.currentState!.validate()) {
                  MyUser myUser = MyUser.empty;
                  myUser.email = emailController.text;
                  myUser.name = nameController.text;
                  imgUrl.isEmpty
                      ? myUser.url =
                          "https://i.ibb.co/6kmLx2D/mypage-avatar.png"
                      : myUser.url = imgUrl;

                  var result = await fireBaseRepo.signUp(
                    myUser,
                    passwordController.text,
                  );
                  if (result == null) {
                    setState(() {
                      error = "이미 사용 중인 이메일입니다";
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
    );
  }
}
