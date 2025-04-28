import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/table_text_row.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TableContainer extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;
  final String orderId;

  TableContainer({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderStream =
        FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots();

    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        children: [
          TbaleTextRow(
            firstElment: '시간',
            secondElment: '현재\n위치',
            thirdElment: '상태',
            style: TextStyles.abeezee16px400wPblack,
          ),
          Divider(color: ColorsManager.primary100),
          StreamBuilder(
            stream: orderStream,

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Order not found.'));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final trackOrder = data['trackOrder'] as List<dynamic>?;

              if (trackOrder == null || trackOrder.isEmpty) {
                return Center(child: Text('No tracking updates yet.'));
              }

              return ListView.builder(
                itemCount: trackOrder.length,
                itemBuilder: (context, index) {
                  final event = trackOrder[index];
                  return TbaleTextRow(
                    firstElment: event['time'],
                    secondElment: event['time'],
                    thirdElment: event['status'],
                    style: TextStyles.abeezee16px400wP600,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
