import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/table_text_row.dart';
import 'package:ecommerece_app/features/review/domain/review_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TableContainer extends ConsumerWidget {
  final String orderId;

  const TableContainer({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDocStreamProvider(orderId));

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
          orderAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Center(child: Text('Order not found.')),
            data: (data) {
              if (data == null) {
                return const Center(child: Text('Order not found.'));
              }

              final trackOrder =
                  data['trackingEvents']?['edges'] as List<dynamic>?;
              if (trackOrder == null || trackOrder.isEmpty) {
                return const Center(child: Text('No tracking updates yet.'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trackOrder.length,
                itemBuilder: (context, index) {
                  final event = trackOrder[index];

                  return TbaleTextRow(
                    firstElment: formatIsoDateTime(event['node']['time']),
                    secondElment: event['node']['status']['name'],
                    thirdElment: event['node']['description'],
                    style: index % 2 == 0
                        ? TextStyles.abeezee16px400wP600
                        : TextStyles.abeezee16px400wPblack,
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

String formatIsoDateTime(
  String isoString, {
  String pattern = 'yyyy-MM-dd HH:mm',
}) {
  try {
    final dateTime = DateTime.parse(isoString);
    final formatter = DateFormat(pattern);
    return formatter.format(dateTime);
  } catch (e) {
    return 'Invalid date';
  }
}
