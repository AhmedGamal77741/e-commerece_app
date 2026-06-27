import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/review/ui/widgets/delivery_status.dart';
import 'package:ecommerece_app/features/review/ui/widgets/delivery_text_row.dart';
import 'package:ecommerece_app/features/review/ui/widgets/table_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrackOrder extends StatelessWidget {
  final Map<String, dynamic> order;
  final String arrivalDate;
  const TrackOrder({super.key, required this.order, required this.arrivalDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('배송조회', style: TextStyles.abeezee16px400wPblack),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(arrivalDate, style: TextStyles.abeezee20px400wPblack),
              verticalSpace(40),
              DeliveryStatus(orderStatus: order['orderStatus']),
              verticalSpace(10),
              DeliveryTextRow(orderStatus: order['orderStatus']),
              verticalSpace(30),
              TableContainer(orderId: order['orderId']),
            ],
          ),
        ),
      ),
    );
  }
}
