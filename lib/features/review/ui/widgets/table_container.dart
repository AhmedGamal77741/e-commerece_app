import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/table_text_row.dart';
import 'package:flutter/material.dart';

class TableContainer extends StatelessWidget {
  const TableContainer({super.key});

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
      child: Column(
        children: [
          TbaleTextRow(
            firstElment: 'Time',
            secondElment: 'Current\nLocation',
            thirdElment: 'Status',
            style: TextStyles.abeezee16px400wPblack,
          ),
          Divider(color: ColorsManager.primary100),
          TbaleTextRow(
            firstElment: '2025-03-26',
            secondElment: 'Cairo',
            thirdElment: 'Delivery\nStarted',
            style: TextStyles.abeezee16px400wP600,
          ),
          TbaleTextRow(
            firstElment: '2025-03-26',
            secondElment: 'Cairo',
            thirdElment: 'Delivery\nStarted',
            style: TextStyles.abeezee16px400wPblack,
          ),
        ],
      ),
    );
  }
}
