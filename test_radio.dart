
import 'package:flutter/material.dart';

Widget test() {
  return RadioGroup<String>(
    groupValue: 'A',
    onChanged: (val) {},
    child: RadioListTile<String>(
      value: 'A',
      title: Text('A'),
    ),
  );
}
