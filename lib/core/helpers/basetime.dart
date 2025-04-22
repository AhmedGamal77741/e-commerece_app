import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<String> getArrivalDay(String meridiem, int baseHour) async {
  await initializeDateFormatting('ko_KR'); // Load Korean date formatting

  meridiem = meridiem.toUpperCase();

  if (meridiem.isEmpty || baseHour < 1 || baseHour > 12) {
    throw ArgumentError("Invalid meridiem or hour");
  }

  DateTime now = DateTime.now();
  int nowHour = int.parse(DateFormat('hh').format(now));
  String nowMeridiem = DateFormat('a').format(now);

  int now24 =
      (nowMeridiem == "PM" && nowHour != 12)
          ? nowHour + 12
          : (nowMeridiem == "AM" && nowHour == 12)
          ? 0
          : nowHour;

  int baseline24 =
      (meridiem == "PM" && baseHour != 12)
          ? baseHour + 12
          : (meridiem == "AM" && baseHour == 12)
          ? 0
          : baseHour;

  int baseOffset = now24 < baseline24 ? 1 : 2;

  int weekday = now.weekday;
  bool isWeekend = (weekday == DateTime.sunday || weekday == DateTime.saturday);

  int totalOffset = baseOffset + (isWeekend ? 2 : 0);

  DateTime arrivalDate = now.add(Duration(days: totalOffset));
  String dayName = DateFormat(
    'EEEE',
    'ko_KR',
  ).format(arrivalDate); // Korean day name

  return "도착일: $dayName"; // Output in Korean
}
