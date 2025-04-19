import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Comments extends StatefulWidget {
  const Comments({super.key});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  bool liked = false;

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            height: 233.h,
            padding: EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: ColorsManager.primary50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20.h,
              children: [
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(color: Colors.white),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Copy Link',
                              style: TextStyle(
                                color: const Color(0xFF343434),
                                fontSize: 16.sp,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40.h,
                              ),
                            ),
                            ImageIcon(
                              AssetImage('assets/icon=link.png'),
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(color: Colors.white),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Not Interested',
                              style: TextStyle(
                                color: const Color(0xFF343434),
                                fontSize: 16.sp,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40.h,
                              ),
                            ),
                            ImageIcon(
                              AssetImage('assets/icon=no_interest.png'),
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(color: Colors.white),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Block',
                              style: TextStyle(
                                color: const Color(0xFFDA3A48),
                                fontSize: 16.sp,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40.h,
                              ),
                            ),
                            ImageIcon(
                              AssetImage('assets/person_off.png'),
                              size: 20.sp,
                              color: const Color(0xFFDA3A48),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(color: Colors.white),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Report',
                              style: TextStyle(
                                color: const Color(0xFFDA3A48),
                                fontSize: 16.sp,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40.h,
                              ),
                            ),
                            ImageIcon(
                              AssetImage('assets/report.png'),
                              size: 20.sp,
                              color: const Color(0xFFDA3A48),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20.h),
                            child: Container(
                              width: 56.w,
                              height: 55.h,
                              decoration: ShapeDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    "https://placehold.co/56x55.png",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                shape: OvalBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10.h,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'stedis.kr',
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_horiz),
                                    onPressed: () {
                                      _showBottomSheet(context);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi interdum tincidunt nisi, sed euismod nibh viverra eu. Phasellus hendrerit et libero vitae malesuada. Sed tempus nisi vitae justo elementum elementum. ',
                                style: TextStyle(
                                  color: const Color(0xFF343434),
                                  fontSize: 16,
                                  fontFamily: 'ABeeZee',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40.h,
                                  letterSpacing: -0.09.w,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 10.w,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 4.w,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            liked = !liked;
                                          });
                                        },
                                        child: ImageIcon(
                                          AssetImage(
                                            liked
                                                ? "assets/icon=like,status=off (1).png"
                                                : "assets/icon=like,status=off.png",
                                          ),
                                          color:
                                              liked ? Colors.red : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '40',
                                        style: TextStyle(
                                          color: const Color(0xFF343434),
                                          fontSize: 14,
                                          fontFamily: 'ABeeZee',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 4,
                                    children: [
                                      ImageIcon(
                                        AssetImage("assets/icon=comment.png"),
                                      ),
                                      Text(
                                        '36',
                                        style: TextStyle(
                                          color: const Color(0xFF343434),
                                          fontSize: 14,
                                          fontFamily: 'ABeeZee',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 50.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20.0.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              'Comments',
                              style: TextStyle(
                                color: const Color(0xFF121212),
                                fontSize: 16,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                              ),
                            ),
                            Text(
                              '77',
                              style: TextStyle(
                                color: const Color(0xFF5F5F5F),
                                fontSize: 16,
                                fontFamily: 'ABeeZee',
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                                letterSpacing: -0.09,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20.0.w),
                        child: InkWell(
                          onTap: () {
                            context.pop();
                          },
                          child: Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          width: 56.w,
                          height: 55.h,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://placehold.co/56x55.png",
                              ),
                              fit: BoxFit.cover,
                            ),
                            shape: OvalBorder(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10.h,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '@happyStudent',
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),
                                ],
                              ),
                              Text(
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi interdum tincidunt nisi, sed euismod nibh viverra eu. Phasellus hendrerit et libero vitae malesuada. Sed tempus nisi vitae justo elementum elementum. ',
                                style: TextStyle(
                                  color: const Color(0xFF343434),
                                  fontSize: 16,
                                  fontFamily: 'ABeeZee',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40.h,
                                  letterSpacing: -0.09.w,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 10.w,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 4.w,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            liked = !liked;
                                          });
                                        },
                                        child: ImageIcon(
                                          AssetImage(
                                            liked
                                                ? "assets/icon=like,status=off (1).png"
                                                : "assets/icon=like,status=off.png",
                                          ),
                                          color:
                                              liked ? Colors.red : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        '40',
                                        style: TextStyle(
                                          color: const Color(0xFF343434),
                                          fontSize: 14,
                                          fontFamily: 'ABeeZee',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              height: 60.h,
              padding: EdgeInsets.symmetric(vertical: 10.0.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // First child is enter comment text input
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0.w),
                      child: TextFormField(
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: ColorsManager.primary600,
                            ),
                          ),
                          labelText: "Add comment",
                          labelStyle: TextStyles.abeezee16px400wP600,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: ColorsManager.primary600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Second child is button
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.send),
                      color: ColorsManager.primary600,
                      iconSize: 25.0.sp,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
