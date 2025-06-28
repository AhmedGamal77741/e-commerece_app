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
  bool? isSub;
  String? subStatus; // 'active', 'canceled', etc.
  DateTime? nextBillingDate;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSubscriptionStatus();
  }

  Future<void> fetchSubscriptionStatus() async {
    if (user != null) {
      final subSnap =
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('nextBillingDate', descending: true)
              .limit(1)
              .get();
      if (subSnap.docs.isNotEmpty) {
        final data = subSnap.docs.first.data();
        setState(() {
          isSub =
              (data['status'] == 'active' ||
                  (data['status'] == 'canceled' &&
                      (data['nextBillingDate']?.toDate()?.isAfter(
                            DateTime.now(),
                          ) ??
                          false)));
          subStatus = data['status'];
          nextBillingDate = data['nextBillingDate']?.toDate();
          loading = false;
        });
      } else {
        setState(() {
          isSub = false;
          subStatus = null;
          nextBillingDate = null;
          loading = false;
        });
      }
    }
  }

  Future<void> cancelSubscriptionDialog() async {
    if (nextBillingDate == null) return;
    final formattedDate =
        "${nextBillingDate!.year}-${nextBillingDate!.month.toString().padLeft(2, '0')}-${nextBillingDate!.day.toString().padLeft(2, '0')}";
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text('프리미엄 멤버십 해지', style: TextStyles.abeezee17px800wPblack),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정말로 프리미엄 멤버십을 해지하시겠습니까?',
                  style: TextStyles.abeezee16px400wPblack,
                ),
                SizedBox(height: 12),
                Text(
                  '해지해도 다음 결제일($formattedDate)까지 프리미엄 혜택이 유지됩니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
                SizedBox(height: 8),
                Text(
                  '다음 결제일 이후에는 자동으로 일반 회원으로 전환됩니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
                SizedBox(height: 8),
                Text(
                  '결제일 이전에 언제든지 재구독할 수 있습니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('취소', style: TextStyle(color: Colors.black)),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              BlackTextButton(
                txt: '해지',
                func: () => Navigator.of(ctx).pop(true),
                style: TextStyles.abeezee16px400wW,
              ),
            ],
          ),
    );
    if (confirmed == true) {
      // Update subscription status to 'canceled'
      final subSnap =
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('nextBillingDate', descending: true)
              .limit(1)
              .get();
      if (subSnap.docs.isNotEmpty) {
        await subSnap.docs.first.reference.update({'status': 'canceled'});
        setState(() {
          subStatus = 'canceled';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해지 요청이 완료되었습니다. 결제일까지 프리미엄 혜택이 유지됩니다.')),
        );
      }
    }
  }

  Future<void> resubscribeDialog() async {
    if (nextBillingDate == null) return;
    final formattedDate =
        "${nextBillingDate!.year}-${nextBillingDate!.month.toString().padLeft(2, '0')}-${nextBillingDate!.day.toString().padLeft(2, '0')}";
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              '프리미엄 멤버십 재구독',
              style: TextStyles.abeezee17px800wPblack,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프리미엄 멤버십을 다시 활성화하시겠습니까?',
                  style: TextStyles.abeezee16px400wPblack,
                ),
                SizedBox(height: 12),
                Text(
                  '다음 결제일($formattedDate)까지 프리미엄 혜택이 유지됩니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
                SizedBox(height: 8),
                Text(
                  '결제일 이후에는 자동 결제가 재개됩니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('취소', style: TextStyle(color: Colors.black)),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              BlackTextButton(
                txt: '재구독',
                func: () => Navigator.of(ctx).pop(true),
                style: TextStyles.abeezee16px400wW,
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final subSnap =
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('nextBillingDate', descending: true)
              .limit(1)
              .get();
      if (subSnap.docs.isNotEmpty) {
        await subSnap.docs.first.reference.update({'status': 'active'});
        setState(() {
          subStatus = 'active';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('재구독이 완료되었습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
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
            if (isSub == true && subStatus == 'active')
              InkWell(
                child: Text(
                  '프리미엄 멤버십 해지',
                  style: TextStyles.abeezee16px400wPblack,
                ),
                onTap: cancelSubscriptionDialog,
              )
            else if (isSub == true &&
                subStatus == 'canceled' &&
                (nextBillingDate?.isAfter(DateTime.now()) ?? false))
              InkWell(
                child: Text('재구독', style: TextStyles.abeezee17px800wPblack),
                onTap: resubscribeDialog,
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
            if (isSub == true && nextBillingDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Text(
                  '다음 결제일: ${nextBillingDate!.year}-${nextBillingDate!.month.toString().padLeft(2, '0')}-${nextBillingDate!.day.toString().padLeft(2, '0')}',
                  style: TextStyles.abeezee11px400wP600,
                ),
              ),
            Text(
              '월 회비 : 3,000원 혜택 : 전 제품 10% 할인',
              style: TextStyles.abeezee11px400wP600,
            ),
            Divider(color: ColorsManager.primary100),
            InkWell(
              child: Text('회원탈퇴', style: TextStyles.abeezee17px800wPblack),
              onTap: () async {
                if (isSub == true) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(
                            '회원탈퇴 안내',
                            style: TextStyles.abeezee17px800wPblack,
                          ),
                          content: Text(
                            '프리미엄 멤버십이 영구적으로 삭제됩니다.\n정말로 회원탈퇴를 진행하시겠습니까?',
                            style: TextStyles.abeezee16px400wPblack,
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                '취소',
                                style: TextStyle(color: Colors.black),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                            BlackTextButton(
                              txt: '탈퇴',
                              func: () => Navigator.of(ctx).pop(true),
                              style: TextStyles.abeezee16px400wW,
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    // Only navigate to delete account, do NOT delete subscriptions here
                    context.go(Routes.deleteAccount);
                  }
                } else {
                  context.go(Routes.deleteAccount);
                }
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
