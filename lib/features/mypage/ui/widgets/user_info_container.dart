import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/mypage/domain/profile_controller.dart';


class UserInfoContainer extends ConsumerStatefulWidget {
  final MyUser currentUser;
  const UserInfoContainer({super.key, required this.currentUser});

  @override
  ConsumerState<UserInfoContainer> createState() => _UserInfoContainerState();
}

class _UserInfoContainerState extends ConsumerState<UserInfoContainer> {
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  /*   final bioController = TextEditingController();
 */
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String imgUrl = "";
  String error = '';

  late MyUser currentUser;

  Future<void> performUpdate({String? newNickname}) async {
    if (!_formKey.currentState!.validate()) return;
    // Check which fields are being updated
    final isUpdatingName =
        newNickname != null &&
        newNickname.isNotEmpty &&
        newNickname != currentUser.name;
    final isUpdatingPassword = passwordController.text.isNotEmpty;
    final isUpdatingPhone =
        phoneController.text.isNotEmpty &&
        phoneController.text != (currentUser.phoneNumber ?? '');

    if (!isUpdatingName && !isUpdatingPassword && !isUpdatingPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("변경된 내용이 없습니다", style: TextStyle(fontSize: 14.sp)),
        ),
      );
      return;
    }

    // Check for unique nickname if updating name
    if (isUpdatingName) {
      final name = newNickname.trim();
      final existing = await ref.read(authRepositoryProvider).isNicknameTaken(name);
      // Only block if the name exists and is not the current user's name
      if (existing && name != currentUser.name) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미 사용 중인 닉네임입니다', style: TextStyle(fontSize: 14.sp)),
          ),
        );
        return;
      }
    }

    // Prepare updated user
    final updatedUser = MyUser(
      userId: currentUser.userId,
      email: currentUser.email,
      name: isUpdatingName ? newNickname : currentUser.name,
      url: imgUrl.isEmpty ? currentUser.url : imgUrl,
      isSub: currentUser.isSub,
      defaultAddressId: currentUser.defaultAddressId,
      blocked: currentUser.blocked,
      payerId: currentUser.payerId,
      isOnline: currentUser.isOnline,
      lastSeen: currentUser.lastSeen,
      chatRooms: currentUser.chatRooms,
      friends: currentUser.friends,
      friendRequestsSent: currentUser.friendRequestsSent,
      friendRequestsReceived: currentUser.friendRequestsReceived,
      phoneNumber:
          isUpdatingPhone ? phoneController.text : currentUser.phoneNumber,
    );
    try {
      if (isUpdatingPassword) {
        final reauth = await _reauthenticateUser(context);
        if (!reauth) return;
      }
      await ref.read(authNotifierProvider.notifier).updateUser(
        updatedUser,
        isUpdatingPassword ? passwordController.text : "",
      );
      if (!mounted) return;
      setState(() {
        currentUser = updatedUser;
      });
      // Clear only updated fields
      if (isUpdatingPassword) passwordController.clear();
      if (isUpdatingPhone) phoneController.clear();

      String successMessage = "";
      List<String> updated = [];
      if (isUpdatingName) updated.add("닉네임");
      if (isUpdatingPassword) updated.add("비밀번호");
      if (isUpdatingPhone) updated.add("전화번호");
      if (updated.isNotEmpty) {
        successMessage = updated.join(", ") + "가 성공적으로 업데이트되었습니다";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage, style: TextStyle(fontSize: 14.sp)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "업데이트 중 오류가 발생했습니다: " + e.toString(),
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;

    _initData();
  }

  @override
  void didUpdateWidget(UserInfoContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      setState(() {
        currentUser = widget.currentUser;
      });
      // Optionally update controllers if they haven't been modified by user
      // but since form fields usually maintain their state until saved,
      // it's safer not to override them unless they are empty or we want to force sync.
    }
  }

  void _initData() {
    nameController.text = currentUser.name.isNotEmpty ? currentUser.name : '';
    emailController.text = currentUser.email;
    phoneController.text =
        (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty)
            ? currentUser.phoneNumber!
            : '';
  }

  Future<bool> _reauthenticateUser(BuildContext context) async {
    bool success = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final TextEditingController reauthController = TextEditingController();
        bool obscure = true;
        IconData icon = Icons.visibility_off;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                '비밀번호 재확인',
                style: TextStyle(color: Colors.black, fontSize: 18.sp),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '비밀번호를 변경하려면 현재 비밀번호를 입력하세요.',
                    style: TextStyle(color: Colors.black, fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                  UnderlineTextField(
                    controller: reauthController,
                    hintText: '현재 비밀번호',
                    obscureText: obscure,
                    keyboardType: TextInputType.visiblePassword,
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? '비밀번호를 입력하세요' : null,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscure = !obscure;
                          icon =
                              obscure ? Icons.visibility_off : Icons.visibility;
                        });
                      },
                      icon: Icon(icon),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                  onPressed: () async {
                    final passwordText = reauthController.text;
                    try {
                      await ref.read(profileControllerProvider).reauthenticateUser(passwordText);
                      success = true;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              '비밀번호 오류: 비밀번호를 확인해주세요.',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    '확인',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return success;
  }

  @override
  void dispose() {
    passwordController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.w, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // userId combo
              // Text(
              //   '아이디', // Translated to Korean
              //   style: TextStyles.abeezee16px400wPblack.copyWith(
              //     fontSize: 16.sp,
              //   ),
              // ),
              // SizedBox(height: 5.h),
              // Container(
              //   width: double.infinity,
              //   padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
              //   decoration: BoxDecoration(
              //     border: Border(
              //       bottom: BorderSide(
              //         color: ColorsManager.primary100,
              //         width: 1.w,
              //       ),
              //     ),
              //   ),
              //   child: Text(
              //     (currentUser?.tag != null && currentUser!.tag!.isNotEmpty)
              //         ? currentUser!.tag!
              //         : '지정되지 않음',
              //     style: TextStyles.abeezee16px400wPblack.copyWith(
              //       color: Colors.grey[700],
              //       fontSize: 16.sp,
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20.h),

              // User bio combo
              Text(
                '아이디', // Translated to Korean
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              IgnorePointer(
                ignoring: true,
                child: UnderlineTextField(
                  controller: emailController,
                  hintText: currentUser.email,
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: 20.h),

              // 전화번호 combo
              Text(
                '전화번호',
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              UnderlineTextField(
                controller: phoneController,
                hintText:
                    (currentUser.phoneNumber != null &&
                            currentUser.phoneNumber!.isNotEmpty)
                        ? currentUser.phoneNumber!
                        : '지정되지 않음',
                obscureText: false,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val!.isEmpty) return null;
                  final koreanReg = RegExp(
                    r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$',
                  );
                  if (!koreanReg.hasMatch(val)) {
                    return '유효한 한국 전화번호를 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // 비밀번호 combo
              Text(
                '비밀번호',
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              Builder(
                builder: (context) {
                  // Use a local stateful widget to persist the obscure/icon state
                  return _PasswordFieldWithVisibility(
                    controller: passwordController,
                  );
                },
              ),
              SizedBox(height: 20.h),
              if (error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this widget at the bottom of the file (or above the class if you prefer)
class _PasswordFieldWithVisibility extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordFieldWithVisibility({Key? key, required this.controller})
    : super(key: key);

  @override
  State<_PasswordFieldWithVisibility> createState() =>
      _PasswordFieldWithVisibilityState();
}

class _PasswordFieldWithVisibilityState
    extends State<_PasswordFieldWithVisibility> {
  bool obscure = true;
  IconData icon = Icons.visibility_off;

  @override
  Widget build(BuildContext context) {
    return UnderlineTextField(
      controller: widget.controller,
      hintText: '영문,숫자 조합',
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      validator: (val) {
        if (val!.isEmpty) return null;
        if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(val)) {
          return '유효한 비밀번호를 입력해 주세요';
        }
        return null;
      },
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            obscure = !obscure;
            icon = obscure ? Icons.visibility_off : Icons.visibility;
          });
        },
        icon: Icon(icon),
      ),
    );
  }
}
