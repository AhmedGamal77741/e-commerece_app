import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            const SizedBox.shrink(),
            SizedBox(width: 20),
            Text("처리 중..."),
          ],
        ),
      );
    },
  );
}
