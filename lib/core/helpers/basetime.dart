import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<String> getArrivalDay(String meridiem, int baseHour) async {
  await initializeDateFormatting('ko_KR');

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
  int daysDifference = arrivalDate.difference(now).inDays;

  // Map for weekday abbreviation
  const weekdayAbbrMap = {
    DateTime.monday: '월',
    DateTime.tuesday: '화',
    DateTime.wednesday: '수',
    DateTime.thursday: '목',
    DateTime.friday: '금',
    DateTime.saturday: '토',
    DateTime.sunday: '일',
  };

  String result;

  if (daysDifference == 1) {
    result = "내일(${weekdayAbbrMap[arrivalDate.weekday]})";
  } else if (daysDifference == 2) {
    result = "모레(${weekdayAbbrMap[arrivalDate.weekday]})";
  } else {
    String dayName = DateFormat(
      'EEEE',
      'ko_KR',
    ).format(arrivalDate); // e.g., 금요일
    result = "도착일: $dayName";
  }

  return result;
}
