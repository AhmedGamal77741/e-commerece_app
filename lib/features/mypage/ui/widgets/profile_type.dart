import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileType extends StatefulWidget {
  final bool isPrivate;
  final String userId;

  const ProfileType({super.key, required this.isPrivate, required this.userId});

  @override
  State<ProfileType> createState() => _ProfileTypeState();
}

class _ProfileTypeState extends State<ProfileType> {
  late bool isPrivate;

  @override
  void initState() {
    super.initState();
    isPrivate = widget.isPrivate;
  }

  Future<void> _updatePrivacy(bool value) async {
    setState(() => isPrivate = value);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'isPrivate': value});
    } catch (e) {
      // If update fails, revert locally and optionally show error
      setState(() => isPrivate = !value);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('설정 업데이트에 실패했습니다. 다시 시도해 주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          isPrivate ? '비공개 프로필' : '공개 프로필',
          style: TextStyles.abeezee17px800wPblack,
        ),
        verticalSpace(20),
        Container(
          decoration: ShapeDecoration(
            color: ColorsManager.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: ColorsManager.primary100),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(15.w, 20.h, 25.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이름', style: TextStyles.abeezee17px800wPblack),
                verticalSpace(30),
                Divider(color: ColorsManager.primary100),
                verticalSpace(10),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '비공개 프로필',
                          style: TextStyles.abeezee17px800wPblack,
                        ),
                        verticalSpace(5),
                        Text(
                          '비공개로 전환하면, 친구로 수락한\n사람만 회원님을 구독하고 게시물\n을 볼 수 있어요.',
                          style: TextStyles.abeezee13px400wP600,
                        ),
                      ],
                    ),
                    Spacer(),
                    Transform.scale(
                      scale: 1.3.sp,
                      child: CupertinoSwitch(
                        value: isPrivate,
                        onChanged: (s) async {
                          await _updatePrivacy(s);
                        },
                        activeTrackColor: Colors.black,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
