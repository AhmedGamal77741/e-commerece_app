import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/payment/payment_service.dart';
import 'package:ecommerece_app/features/payment/payment_web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

class UserOptionsContainer extends StatefulWidget {
  const UserOptionsContainer({super.key});

  @override
  State<UserOptionsContainer> createState() => _UserOptionsContainerState();
}

class _UserOptionsContainerState extends State<UserOptionsContainer> {
  bool? isSub;
  final user = FirebaseAuth.instance.currentUser;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  @override
  void initState() {
    super.initState();
    fetchSubscriptionStatus();
  }

  Future<void> fetchSubscriptionStatus() async {
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      if (doc.exists) {
        setState(() {
          isSub = doc.data()?['isSub'] ?? false;
        });
      }
    }
  }

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
            if (isSub == null)
              const CircularProgressIndicator()
            else if (isSub == true)
              InkWell(
                child: Text('cancel', style: TextStyles.abeezee16px400wPblack),
                onTap: () {
                  context.go(Routes.cancelSubscription);
                },
              )
            else
              InkWell(
                child: Text(
                  'Subscribe',
                  style: TextStyles.abeezee16px400wPblack,
                ),
                onTap: () async {
                  _launchPaymentPage('3000', user!.uid);
                },
              ),
            Divider(color: ColorsManager.primary100),
            InkWell(
              child: Text('고객센터', style: TextStyles.abeezee16px400wPblack),
              onTap: () {},
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
  print(url);
  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // Forces external browser
    );
  } else {
    throw 'Could not launch $url';
  }
}
