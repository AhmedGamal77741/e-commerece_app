import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileType extends ConsumerStatefulWidget {
  final bool isPrivate;
  final String userId;
  final TextEditingController nicknameController;

  const ProfileType({
    super.key,
    required this.isPrivate,
    required this.userId,
    required this.nicknameController,
  });

  @override
  ConsumerState<ProfileType> createState() => _ProfileTypeState();
}

class _ProfileTypeState extends ConsumerState<ProfileType> {
  late bool isPrivate;

  @override
  void initState() {
    super.initState();
    isPrivate = widget.isPrivate;
  }

  Future<void> _updatePrivacy(bool value) async {
    final wasPrivate = isPrivate;
    setState(() => isPrivate = value);
    try {
      await ref.read(profileControllerProvider.notifier).updatePrivacy(value, widget.userId);
    } catch (e) {
      if (mounted) {
        setState(() => isPrivate = wasPrivate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정 업데이트에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
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
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('닉네임', style: TextStyles.abeezee17px800wPblack),
                verticalSpace(5),
                TextField(
                  controller: widget.nicknameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    hintText: '닉네임 입력',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                verticalSpace(20),
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
                    const Spacer(),
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
