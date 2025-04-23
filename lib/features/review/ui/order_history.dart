import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/review/ui/widgets/text_and_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('You must be logged in to view orders.'));
    }

    final orderStream =
        FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: orderStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        final orders = snapshot.data!.docs;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: ListView.separated(
            itemCount: orders.length,
            separatorBuilder:
                (context, index) => Divider(color: ColorsManager.primary300),
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 1.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextAndButtons(
                        orderId: data['orderId'],
                        orderDate: formatDate(data['orderDate']),
                        orderStatus: data['status'],
                        orderPrice: data['totalPrice'].toString(),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // maybe show options for details
                      },
                      icon: Icon(
                        Icons.more_horiz,
                        color: ColorsManager.primary600,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
          ),
        );
      },
    );
  }
}

String formatDate(String isoDate) {
  final dateTime = DateTime.parse(isoDate);
  final formatter = DateFormat('yyyy-MM-dd – kk:mm');
  return formatter.format(dateTime);
}
