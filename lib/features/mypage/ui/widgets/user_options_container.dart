import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/widgets/no_account_screen.dart';
import 'package:ecommerece_app/core/widgets/receipt_setup_screen.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class UserOptionsContainer extends ConsumerStatefulWidget {
  final bool isSub;
  const UserOptionsContainer({super.key, required this.isSub});

  @override
  ConsumerState<UserOptionsContainer> createState() => _UserOptionsContainerState();
}

class _UserOptionsContainerState extends ConsumerState<UserOptionsContainer>
    with RouteAware {
  final String supportUserId = 'JuxEfED9YSc2XyHRFgkPcNCFUSJ3';
  bool _isLoading = false;

  Future<void> openSupportChat(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(profileControllerProvider.notifier).openSupportChat(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> resubscribeDialog(DateTime nextBillingDate) async {
    final formattedDate =
        "${nextBillingDate.year}-${nextBillingDate.month.toString().padLeft(2, '0')}-${nextBillingDate.day.toString().padLeft(2, '0')}";
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
                const SizedBox(height: 12),
                Text(
                  '다음 결제일($formattedDate)까지 프리미엄 혜택이 유지됩니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
                const SizedBox(height: 8),
                Text(
                  '결제일 이후에는 자동 결제가 재개됩니다.',
                  style: TextStyles.abeezee13px400wP600,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('취소', style: TextStyle(color: Colors.black)),
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
      try {
        await ref.read(profileControllerProvider.notifier).resubscribe();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('재구독이 완료되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('재구독에 실패했습니다.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    
    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    final isSupport = user.uid == supportUserId;
    final subAsyncValue = ref.watch(subscriptionStreamProvider);

    return subAsyncValue.when(
      data: (snapshot) {
        bool? isSub = widget.isSub;
        String? subStatus;
        DateTime? nextBillingDate;
        
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          isSub = (data['status'] == 'active' ||
              (data['status'] == 'canceled' &&
                  (data['nextBillingDate']?.toDate()?.isAfter(DateTime.now()) ?? false)));
          subStatus = data['status'];
          nextBillingDate = data['nextBillingDate']?.toDate();
        } else {
          isSub = false;
          subStatus = null;
          nextBillingDate = null;
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
                Container(
                  decoration: BoxDecoration(
                    color: isSupport ? Colors.grey[200] : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: (isSupport || _isLoading) ? null : () => openSupportChat(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '고객센터 연결',
                                style: TextStyles.abeezee17px800wPblack.copyWith(
                                  color: isSupport ? Colors.grey : null,
                                ),
                              ),
                              Text(
                                '고객센터 운영시간 : 09:00시 ~ 16:30시',
                                style: TextStyles.abeezee11px400wP600.copyWith(
                                  color: isSupport ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                          if (_isLoading) const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(color: ColorsManager.primary100),
                if (isSub == true && subStatus == 'active')
                  InkWell(
                    child: Text('프리미엄 멤버십 해지', style: TextStyles.abeezee17px800wPblack),
                    onTap: () async {
                      if (context.mounted) {
                        await context.push(Routes.cancelSubscription);
                      }
                    },
                  )
                else if (isSub == true &&
                    subStatus == 'canceled' &&
                    (nextBillingDate?.isAfter(DateTime.now()) ?? false))
                  InkWell(
                    onTap: nextBillingDate == null ? null : () => resubscribeDialog(nextBillingDate!),
                    child: Text('재구독', style: TextStyles.abeezee17px800wPblack),
                  )
                else
                  InkWell(
                    child: Text('프리미엄 멤버십 가입', style: TextStyles.abeezee17px800wPblack),
                    onTap: () => _navigateToSubscription(context, ref),
                  ),
                if (isSub == true && nextBillingDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Text(
                      '다음 결제일: ${nextBillingDate.year}-${nextBillingDate.month.toString().padLeft(2, '0')}-${nextBillingDate.day.toString().padLeft(2, '0')}',
                      style: TextStyles.abeezee11px400wP600,
                    ),
                  ),
                Text('월 회비 : 8,000원 혜택 : 전 제품 20% 할인', style: TextStyles.abeezee11px400wP600),
                Divider(color: ColorsManager.primary100),
                InkWell(
                  child: Text('회원탈퇴', style: TextStyles.abeezee17px800wPblack),
                  onTap: () async {
                    if (isSub == true) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text('회원탈퇴 안내', style: TextStyles.abeezee17px800wPblack),
                          content: Text(
                            '프리미엄 멤버십이 영구적으로 삭제됩니다.\n정말로 회원탈퇴를 진행하시겠습니까?',
                            style: TextStyles.abeezee16px400wPblack,
                          ),
                          actions: [
                            TextButton(
                              child: const Text('취소', style: TextStyle(color: Colors.black)),
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
                        if (context.mounted) {
                          context.push(Routes.deleteAccount);
                        }
                      }
                    } else {
                      if (context.mounted) {
                        context.push(Routes.deleteAccount);
                      }
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
                Text('‘좋은 제품 좋은 가격’ 이라면 누구나 입점 가능합니다.', style: TextStyles.abeezee11px400wP600),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const Center(child: Text('오류가 발생했습니다.')),
    );
  }
}

void _launchPartnerPage() async {
  final url = Uri.parse('https://link.inpock.co.kr/pang2chocolate');
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}

Future<void> _navigateToSubscription(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(profileControllerProvider.notifier);
  
  final hasBankAccount = await controller.checkBankAccount();

  if (!hasBankAccount) {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NoBankAccountScreen(source: 'sub'),
      ),
    );
    final nowHasAccount = await controller.refreshBankAccount();
    if (!nowHasAccount) return;
  }

  final hasReceiptData = await controller.checkReceiptData();

  if (!hasReceiptData) {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ReceiptSetupScreen(source: 'sub'),
      ),
    );
    if (result != true) return;
  }

  if (context.mounted) {
    context.push(Routes.subscriptionScreen);
  }
}
