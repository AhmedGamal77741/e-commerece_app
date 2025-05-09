import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/features/mypage/data/firebas_funcs.dart';
import 'package:ecommerece_app/features/payment/payment_service.dart';
import 'package:ecommerece_app/features/payment/payment_web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class UserOptionsContainer extends StatefulWidget {
  final bool isSub;
  const UserOptionsContainer({super.key, required this.isSub});

  @override
  State<UserOptionsContainer> createState() => _UserOptionsContainerState();
}

class _UserOptionsContainerState extends State<UserOptionsContainer> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // fetchSubscriptionStatus();
  }

  // Future<void> fetchSubscriptionStatus() async {
  //   if (user != null) {
  //     final doc =
  //         await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(user!.uid)
  //             .get();
  //     if (doc.exists) {
  //       setState(() {
  //         isSub = doc.data()?['isSub'] ?? false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text('고객센터 연결', style: TextStyles.abeezee17px800wPblack),
            Text(
              '고객센터 운영시간 : 10:00시 ~ 23:00시',
              style: TextStyles.abeezee11px400wP600,
            ),
            Divider(color: ColorsManager.primary100),
            if (widget.isSub == true)
              InkWell(
                child: Text('cancel', style: TextStyles.abeezee16px400wPblack),
                onTap: () {
                  context.go(Routes.cancelSubscription);
                },
              )
            else
              InkWell(
                child: Text(
                  '프리미엄 멤버십 가입',
                  style: TextStyles.abeezee17px800wPblack,
                ),
                onTap: () async {
                  _launchPaymentPage('3000', user!.uid);
                },
              ),
            Text(
              '월 회비 : 3,000원 혜택 : 전 제품 10% 할인',
              style: TextStyles.abeezee11px400wP600,
            ),
            Divider(color: ColorsManager.primary100),
            InkWell(
              child: Text('회원탈퇴', style: TextStyles.abeezee17px800wPblack),
              onTap: () {
                showDeleteAccountDialog(context);
              },
            ),
            Text('멤버십 해지 후 탈퇴 가능합니다.', style: TextStyles.abeezee11px400wP600),
            Divider(color: ColorsManager.primary100),
            InkWell(
              child: Text('입점신청', style: TextStyles.abeezee17px800wPblack),
              onTap: () {
                _launchPartnerPage();
              },
            ),
            Text(
              '‘좋은 제품 좋은 가격’ 이라면 누구나 입점 가능합니다.',
              style: TextStyles.abeezee11px400wP600,
            ),
          ],
        ),
      ),
    );
  }
}

void _launchPaymentPage(String amount, String userId) async {
  final url = Uri.parse(
    'https://e-commerce-app-34fb2.web.app/payment.html?amount=$amount&userId=$userId',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      // mode: LaunchMode.externalApplication, // Forces external browser
    );
  } else {
    throw 'Could not launch $url';
  }
}

void _launchPartnerPage() async {
  final url = Uri.parse('https://tally.so/r/w5O556');

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      // mode: LaunchMode.externalApplication, // Forces external browser
    );
  } else {
    throw 'Could not launch $url';
  }
}

void showDeleteAccountDialog(BuildContext context) {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? errorMsg;
  IconData iconPassword = Icons.visibility;
  bool obsecurepassword = true;
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,

            title: const Text('탈퇴 확인'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UnderlineTextField(
                    controller: emailController,
                    hintText: '이메일',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                    errorMsg: errorMsg,
                    validator: (val) {
                      if (val!.isEmpty) {
                        return 'Please fill in this field';
                      } else if (!RegExp(
                        r'^[\w-\.]+@([\w-]+.)+[\w-]{2,4}$',
                      ).hasMatch(val)) {
                        return '유효한 이메일을 입력해 주세요';
                      }
                      return null;
                    },
                  ),
                  verticalSpace(12),
                  UnderlineTextField(
                    controller: passwordController,
                    hintText: '영문,숫자 조합',
                    obscureText: obsecurepassword,
                    keyboardType: TextInputType.visiblePassword,
                    errorMsg: errorMsg,
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
            actions: [
              TextButton(
                child: Text('취소 ', style: TextStyles.abeezee13px400wPblack),
                onPressed: () => Navigator.of(context).pop(),
              ),
              BlackTextButton(
                txt: '계정 삭제',
                func: () async {
                  if (!formKey.currentState!.validate()) return;

                  setState(() => isLoading = true);
                  try {
                    await reauthenticateAndDeleteUser(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );
                    Navigator.of(context).pop(); // close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                      ),
                    );
                  } catch (e) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                style: TextStyles.abeezee14px400wW,
              ),
            ],
          );
        },
      );
    },
  );
}
