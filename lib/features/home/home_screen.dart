import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            child: SizedBox(
              width: 393.w,
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
                              SizedBox(
                                child: Text(
                                  'Not Interested',
                                  style: TextStyle(
                                    color: const Color(0xFF343434),
                                    fontSize: 16.sp,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w400,
                                    height: 1.40.h,
                                  ),
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
                              SizedBox(
                                child: Text(
                                  'Block',
                                  style: TextStyle(
                                    color: const Color(0xFFDA3A48),
                                    fontSize: 16.sp,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w400,
                                    height: 1.40.h,
                                  ),
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
                              SizedBox(
                                child: Text(
                                  'Report',
                                  style: TextStyle(
                                    color: const Color(0xFFDA3A48),
                                    fontSize: 16.sp,
                                    fontFamily: 'ABeeZee',
                                    fontWeight: FontWeight.w400,
                                    height: 1.40.h,
                                  ),
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
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: TabAppBar(firstTab: 'Recommendations'),
        body: TabBarView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(Routes.notificationsScreen);
                        },
                        child: Stack(
                          children: [
                            Container(
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
                            Positioned(
                              right: 0.w,
                              top: 0.h,
                              child: Container(
                                width: 18.w,
                                height: 18.h,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFDA3A48),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(Routes.addPostScreen);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10.h,
                            children: [
                              Text(
                                'pang2chocolate',
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                              Text(
                                'How was your day today?',
                                style: TextStyle(
                                  color: const Color(0xFF5F5F5F),
                                  fontSize: 13.sp,
                                  fontFamily: 'ABeeZee',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                //POSTS
                Divider(),
                Row(
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
                      child: Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10.h,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4.w,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          liked = !liked;
                                        });
                                      },
                                      child: SizedBox(
                                        width: 22.w,
                                        height: 22.h,
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
                                    ),
                                    SizedBox(
                                      width: 25,
                                      height: 22,
                                      child: Text(
                                        '40',
                                        style: TextStyle(
                                          color: const Color(0xFF343434),
                                          fontSize: 14,
                                          fontFamily: 'ABeeZee',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        context.pushNamed(
                                          Routes.commentsScreen,
                                        );
                                      },
                                      child: SizedBox(
                                        width: 22.w,
                                        height: 22.h,
                                        child: ImageIcon(
                                          AssetImage("assets/icon=comment.png"),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 25,
                                      height: 22,
                                      child: Text(
                                        '36',
                                        style: TextStyle(
                                          color: const Color(0xFF343434),
                                          fontSize: 14,
                                          fontFamily: 'ABeeZee',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40,
                                        ),
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
          ],
        ),
      ),
    );
  }
}
