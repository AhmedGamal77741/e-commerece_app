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
  String imgUrl = "";
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
                          Text(
                            'Nickname',
                            style: TextStyles.abeezee16px400wPblack,
                          ),
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
                        hintText: 'Enter Your Name',
                        obscureText: false,
                        keyboardType: TextInputType.name,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return 'Enter Yout Name';
                          } else if (val.length > 30) {
                            return 'Name too long';
                          }
                          return null;
                        },
                      ),
                      verticalSpace(20),
                      Text('E-mail', style: TextStyles.abeezee16px400wPblack),
                      UnderlineTextField(
                        controller: emailController,
                        hintText: 'Enter Your Email',
                        obscureText: false,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return 'Please fill in this field';
                          } else if (!RegExp(
                            r'^[\w-\.]+@([\w-]+.)+[\w-]{2,4}$',
                          ).hasMatch(val)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      verticalSpace(20),
                      Text('Password', style: TextStyles.abeezee16px400wPblack),
                      UnderlineTextField(
                        controller: passwordController,
                        hintText: 'Password',
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
                            return 'Please fill in this field';
                          } else if (!RegExp(
                            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~`)\%\-(_+=;:,.<>/?"[{\]}\|^]).{8,}$',
                          ).hasMatch(val)) {
                            return 'Please enter a valid password';
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
                    Text(
                      'Monthly Subscription',
                      style: TextStyles.abeezee16px400wPblack,
                    ),
                    Text('3,000 KRW', style: TextStyles.abeezee14px400wP600),
                    Divider(color: ColorsManager.primary100),
                    Text('Benefits', style: TextStyles.abeezee16px400wPblack),
                    Text(
                      'Free shipping for all products, Free return,\nMembership Community, Guaranteed lowest price ',
                      style: TextStyles.abeezee14px400wP600,
                    ),
                    Divider(color: ColorsManager.primary100),
                    Text('Payment', style: TextStyles.abeezee16px400wPblack),
                    Text(
                      'Enter Payment Detail',
                      style: TextStyles.abeezee14px400wP600,
                    ),
                    Divider(color: ColorsManager.primary100),
                  ],
                ),
              ),
            ),
            verticalSpace(40),
            WideTextButton(
              txt: 'Sign up',
              func: () async {
                if (_formKey.currentState!.validate()) {
                  MyUser myUser = MyUser.empty;
                  myUser.email = emailController.text;
                  myUser.name = nameController.text;
                  myUser.url = imgUrl;
                  var result = await fireBaseRepo.signUp(
                    myUser,
                    passwordController.text,
                  );
                  if (result == null) {
                    setState(() {
                      error = "Email Already in use";
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
