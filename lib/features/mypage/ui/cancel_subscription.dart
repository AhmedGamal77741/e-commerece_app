import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CancelSubscription extends ConsumerStatefulWidget {
  const CancelSubscription({super.key});

  @override
  ConsumerState<CancelSubscription> createState() => _CancelSubscriptionState();
}

List<String> options = ['단순 변심으로 인한 해지', '타사 앱 사용으로 인한 해지', '서비스 불만으로 인한 해지', '기타'];

class _CancelSubscriptionState extends ConsumerState<CancelSubscription> {
  String currentOption = options[0];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('샤이닝 프리미엄 멤버십 해지', style: TextStyles.abeezee16px400wPblack),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '서비스 개선을 위해\n멤버십을 해지하는 이유를\n알려주세요',
                textAlign: TextAlign.center,
                style: TextStyles.abeezee20px400wPblack,
              ),
              verticalSpace(30),
              for (var option in options)
                ListTile(
                  title: Text(
                    option,
                    style: TextStyles.abeezee16px400wPblack,
                  ),
                  leading: Radio(
                    value: option,
                    groupValue: currentOption,
                    onChanged: (val) {
                      setState(() {
                        currentOption = val.toString();
                      });
                    },
                  ),
                ),
              verticalSpace(30),
              WideTextButton(
                txt: '해지 신청',
                color: Colors.white,
                txtColor: ColorsManager.primaryblack,
                func: () async {
                  final navigator = Navigator.of(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(
                            '샤이닝 프리미엄 멤버십 해지',
                            style: TextStyles.abeezee17px800wPblack,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '정말로 샤이닝 프리미엄 멤버십을 해지하시겠습니까?',
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '해지 신청시 더 이상 샤이닝 프리미엄 혜택을 받으실수 없습니다.',
                                style: TextStyles.abeezee13px400wP600,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '이미 결제된 금액에 대해서는 환불되지 않습니다.',
                                style: TextStyles.abeezee13px400wP600,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '해지 신청일 기준 다음 결제일부터 요금이 청구되지 않습니다.',
                                style: TextStyles.abeezee13px400wP600,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                '취소',
                                style: TextStyle(color: Colors.black),
                              ),
                              onPressed: () => navigator.pop(false),
                            ),
                            WideTextButton(
                              txt: '해지',
                              color: Colors.black,
                              txtColor: Colors.white,
                              func: () => navigator.pop(true),
                            ),
                          ],
                        ),
                  );
                  if (confirmed != true) return;
                  
                  try {
                    await ref.read(profileControllerProvider).cancelSubscription(currentOption);
                    if (mounted) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('멤버십 해지가 성공적으로 처리되었습니다.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('해지 처리에 실패했습니다. 다시 시도해주세요.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
