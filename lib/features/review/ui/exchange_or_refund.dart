import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/wide_text_button.dart';
import 'package:ecommerece_app/features/review/ui/widgets/exchage_body.dart';
import 'package:ecommerece_app/features/review/ui/widgets/refund_body.dart';
import 'package:ecommerece_app/features/review/ui/widgets/req_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExchangeOrRefund extends StatefulWidget {
  const ExchangeOrRefund({super.key});

  @override
  State<ExchangeOrRefund> createState() => _ExchangeOrRefundState();
}

class _ExchangeOrRefundState extends State<ExchangeOrRefund> {
  bool isRefund = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsManager.white,
        title: Text(
          'Request Exchange/Refund',
          style: TextStyles.abeezee16px400wPblack,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ReqButton(
                      txt: 'Refund',
                      color:
                          isRefund
                              ? ColorsManager.primaryblack
                              : ColorsManager.primary500,
                      func: () {
                        if (!isRefund) {
                          setState(() {
                            isRefund = true;
                          });
                        }
                      },
                    ),
                    horizontalSpace(20),
                    ReqButton(
                      txt: 'Exchange',
                      color:
                          isRefund
                              ? ColorsManager.primary500
                              : ColorsManager.primaryblack,
                      func: () {
                        if (isRefund) {
                          setState(() {
                            isRefund = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
                verticalSpace(50),
                isRefund ? RefundBody() : ExchangeBody(),
                verticalSpace(50),
                WideTextButton(txt: 'Request', func: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
