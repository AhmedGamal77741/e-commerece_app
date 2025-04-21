import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyStory extends StatefulWidget {
  const MyStory({super.key});

  @override
  State<MyStory> createState() => _MyStoryState();
}

class _MyStoryState extends State<MyStory> {
  bool liked = false;
  @override
  Widget build(BuildContext context) {
    return Row(
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
                  image: NetworkImage("https://placehold.co/56x55.png"),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('stedis.kr', style: TextStyles.abeezee16px400wPblack),
                  IconButton(icon: Icon(Icons.more_horiz), onPressed: () {}),
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
                            color: liked ? Colors.red : Colors.black,
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
                          // context.pushNamed(Routes.commentsScreen);
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
      ],
    );
  }
}
