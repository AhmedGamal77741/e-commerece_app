import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsManager.primary200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Circular edges
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ), // Width/height
            elevation: 0,
          ),
          child: Text("Post", style: TextStyle(color: Colors.white)),
        ),
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false, // Don't show the leading button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios),
              ),
              Text(
                "Today’s Story",
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 16,
                  fontFamily: 'ABeeZee',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            verticalSpace(20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
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
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    width: 172.w,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 15.h,
                      children: [
                        Text(
                          'pang2chocolate',
                          style: TextStyles.abeezee16px400wPblack,
                        ),
                        Text(
                          'Any Updates?',
                          style: TextStyle(
                            color: const Color(0xFF5F5F5F),
                            fontSize: 13.sp,
                            fontFamily: 'ABeeZee',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        ImageIcon(
                          AssetImage('assets/image_icon.png'),
                          size: 17.sp,
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
    );
  }
}
