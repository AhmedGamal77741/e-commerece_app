import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/no_account_screen.dart';
import 'package:ecommerece_app/core/widgets/receipt_setup_screen.dart';

import 'package:ecommerece_app/features/shop/domain/shop_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ShiningPremiumBanner extends ConsumerStatefulWidget {
  const ShiningPremiumBanner({super.key});

  @override
  ConsumerState<ShiningPremiumBanner> createState() =>
      _ShiningPremiumBannerState();
}

class _ShiningPremiumBannerState extends ConsumerState<ShiningPremiumBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w, // NEW UI: responsive padding
        vertical: 30.h, // NEW UI: responsive padding
      ),
      child: Column(
        children: [
          Container(
            decoration: ShapeDecoration(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 2, color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  verticalSpace(15),
                  Text(
                    '멤버십 혜택',
                    style: TextStyles.abeezee30px800wW.copyWith(
                      fontFamily: 'ABeeZee',
                    ),
                  ),
                  verticalSpace(50),
                  Text(
                    '월회비 8,000원\n모든 제품 20% 할인',
                    textAlign: TextAlign.center,
                    style: TextStyles.abeezee18px400wPblack.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  verticalSpace(50),
                  Text(
                    '매월 5만원 이상 구매하시는 분은 멤버십 가입을 권합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyles.abeezee18px400wPblack.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          verticalSpace(15),
          TextButton(
            onPressed: () {
              final currentUser = ref.read(authStateProvider).value;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다")),
                );
                return;
              }
              _navigateToSubscriptionFromBanner(context, ref, currentUser.uid);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: WidgetStateProperty.all(Size(double.infinity, 80.h)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  side: const BorderSide(color: Colors.black, width: 0.6),
                ),
              ),
            ),
            child: Text(
              '멤버십 가입하기',
              style: TextStyles.abeezee23px800wW.copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _navigateToSubscriptionFromBanner(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  final shopNotifier = ref.read(shopControllerProvider.notifier);

  // -- Gate 1: bank account
  bool hasBankAccount = await shopNotifier.checkUserHasBankAccount(uid);
  if (!hasBankAccount) {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NoBankAccountScreen(source: 'sub'),
      ),
    );
    hasBankAccount = await shopNotifier.checkUserHasBankAccount(uid);
    if (!hasBankAccount) return;
  }

  // -- Gate 2: receipt / invoice data
  bool hasReceiptData = await shopNotifier.checkUserHasReceiptData(uid);
  if (!hasReceiptData) {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ReceiptSetupScreen(source: 'sub'),
      ),
    );
    if (result != true) return;
  }

  // -- All gates passed
  if (context.mounted) {
    context.push(Routes.subscriptionScreen);
  }
}
