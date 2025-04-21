import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CancelSubscription extends StatefulWidget {
  const CancelSubscription({super.key});

  @override
  State<CancelSubscription> createState() => _CancelSubscriptionState();
}

List<String> options = ['비싼 구독료', '쇼핑 시간 단축', '찾고 있는 상품을 찾을 수 없음', '기타'];

class _CancelSubscriptionState extends State<CancelSubscription> {
  String currentOption = options[0];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Column(
            children: [
              Text('왜 떠나는지 알려주세요', style: TextStyles.abeezee20px400wPblack),
              verticalSpace(30),
              ListTile(
                title: Text(
                  options[0],
                  style: TextStyles.abeezee16px400wPblack,
                ),
                leading: Radio(
                  value: options[0],
                  groupValue: currentOption,
                  onChanged: (val) {
                    setState(() {
                      currentOption = val.toString();
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  options[1],
                  style: TextStyles.abeezee16px400wPblack,
                ),
                leading: Radio(
                  value: options[1],
                  groupValue: currentOption,
                  onChanged: (val) {
                    setState(() {
                      currentOption = val.toString();
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  options[2],
                  style: TextStyles.abeezee16px400wPblack,
                ),
                leading: Radio(
                  value: options[2],
                  groupValue: currentOption,
                  onChanged: (val) {
                    setState(() {
                      currentOption = val.toString();
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  options[3],
                  style: TextStyles.abeezee16px400wPblack,
                ),
                leading: Radio(
                  value: options[3],
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
                txt: '구독 취소n',
                color: Colors.white,
                txtColor: ColorsManager.primaryblack,
                func: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
