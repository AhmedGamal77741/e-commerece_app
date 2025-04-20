import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final passwordController = TextEditingController();

  final emailController = TextEditingController();

  IconData iconPassword = Icons.visibility;

  bool obsecurepassword = true;

  final _formKey = GlobalKey<FormState>();

  String? _errorMsg;

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
                      verticalSpace(20),
                      Text('Email', style: TextStyles.abeezee16px400wPblack),
                      UnderlineTextField(
                        controller: emailController,
                        hintText: 'Email',
                        obscureText: false,
                        keyboardType: TextInputType.emailAddress,
                        errorMsg: _errorMsg,
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
                        obscureText: obsecurepassword,
                        keyboardType: TextInputType.visiblePassword,
                        errorMsg: _errorMsg,
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
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obsecurepassword = !obsecurepassword;
                              if (obsecurepassword) {
                                iconPassword = Icons.visibility_off;
                              } else {
                                iconPassword = Icons.visibility;
                              }
                            });
                          },
                          icon: Icon(iconPassword),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            verticalSpace(30),
            Text(error, style: TextStyles.abeezee16px400wPred),
            WideTextButton(
              txt: 'Sign in',
              func: () async {
                if (_formKey.currentState!.validate()) {
                  dynamic result = await fireBaseRepo.signIn(
                    emailController.text,
                    passwordController.text,
                  );

                  if (result == null) {
                    setState(() {
                      error = 'invaid mail or password';
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
