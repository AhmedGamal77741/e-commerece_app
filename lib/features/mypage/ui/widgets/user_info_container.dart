import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class UserInfoContainer extends StatefulWidget {
  const UserInfoContainer({super.key});

  @override
  State<UserInfoContainer> createState() => _UserInfoContainerState();
}

class _UserInfoContainerState extends State<UserInfoContainer> {
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String imgUrl = "";
  String error = '';
  final fireBaseRepo = FirebaseUserRepo();

  MyUser? currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Provider.of<PostsProvider>(context, listen: false).startListening();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await FirebaseUserRepo().user.first;
      if (!mounted) return;
      if (user != null) {
        setState(() {
          currentUser = user;
          nameController.text = user.name.isNotEmpty ? user.name : '';
          bioController.text =
              (user.bio != null && user.bio!.isNotEmpty) ? user.bio! : '';
          phoneController.text =
              (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  ? user.phoneNumber!
                  : '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading user: $e');
    }
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
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null || user.email == null) {
                        throw Exception('로그인 정보가 없습니다');
                      }
                      final cred = EmailAuthProvider.credential(
                        email: user.email!,
                        password: passwordText,
                      );
                      await user.reauthenticateWithCredential(cred);
                      success = true;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              '재인증 실패: 비밀번호를 확인하세요.',
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
    bioController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.w, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // userId combo
              Text(
                '아이디', // Translated to Korean
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: ColorsManager.primary100,
                      width: 1.w,
                    ),
                  ),
                ),
                child: Text(
                  (currentUser?.tag != null && currentUser!.tag!.isNotEmpty)
                      ? currentUser!.tag!
                      : '지정되지 않음',
                  style: TextStyles.abeezee16px400wPblack.copyWith(
                    color: Colors.grey[700],
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // 닉네임 combo
              Text(
                '닉네임',
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              UnderlineTextField(
                controller: nameController,
                hintText:
                    (currentUser?.name.isNotEmpty ?? false)
                        ? currentUser!.name
                        : '지정되지 않음',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val!.isEmpty) return null;
                  if (val.length > 30) return '이름이 너무 깁니다';
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // User bio combo
              Text(
                '소개', // Translated to Korean
                style: TextStyles.abeezee16px400wPblack.copyWith(
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 5.h),
              UnderlineTextField(
                controller: bioController,
                hintText:
                    (currentUser?.bio != null && currentUser!.bio!.isNotEmpty)
                        ? currentUser!.bio!
                        : '지정되지 않음',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val!.isEmpty) return null;
                  if (val.length > 30) return '이름이 너무 깁니다';
                  return null;
                },
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
                    (currentUser?.phoneNumber != null &&
                            currentUser!.phoneNumber!.isNotEmpty)
                        ? currentUser!.phoneNumber!
                        : '지정되지 않음',
                obscureText: false,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val!.isEmpty) return null;
                  final koreanReg = RegExp(r'^(01[016789])-?\d{3,4}-?\d{4} $');
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

              // Submit button row as a combo
              Row(
                children: [
                  const Spacer(),
                  BlackTextButton(
                    txt: '완료',
                    func: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (currentUser == null) return;
                      // Check if any field is being updated
                      final isUpdatingName =
                          nameController.text.isNotEmpty &&
                          nameController.text != currentUser!.name;
                      final isUpdatingPassword =
                          passwordController.text.isNotEmpty;
                      final isUpdatingPhone =
                          phoneController.text.isNotEmpty &&
                          phoneController.text !=
                              (currentUser!.phoneNumber ?? '');
                      final isUpdatingBio =
                          bioController.text.isNotEmpty &&
                          bioController.text != (currentUser!.bio ?? '');

                      if (!isUpdatingName &&
                          !isUpdatingPassword &&
                          !isUpdatingPhone &&
                          !isUpdatingBio) {
                        setState(() {
                          error = "변경된 내용이 없습니다";
                        });
                        return;
                      }

                      // Prepare updated user
                      final updatedUser = MyUser(
                        userId: currentUser!.userId,
                        email: currentUser!.email,
                        name:
                            isUpdatingName
                                ? nameController.text
                                : currentUser!.name,
                        url: imgUrl.isEmpty ? currentUser!.url : imgUrl,
                        isSub: currentUser!.isSub,
                        defaultAddressId: currentUser!.defaultAddressId,
                        blocked: currentUser!.blocked,
                        payerId: currentUser!.payerId,
                        isOnline: currentUser!.isOnline,
                        lastSeen: currentUser!.lastSeen,
                        chatRooms: currentUser!.chatRooms,
                        friends: currentUser!.friends,
                        friendRequestsSent: currentUser!.friendRequestsSent,
                        friendRequestsReceived:
                            currentUser!.friendRequestsReceived,
                        bio:
                            isUpdatingBio
                                ? bioController.text
                                : currentUser!.bio,
                        phoneNumber:
                            isUpdatingPhone
                                ? phoneController.text
                                : currentUser!.phoneNumber,
                        tag: currentUser!.tag,
                      );
                      try {
                        if (isUpdatingPassword) {
                          final reauth = await _reauthenticateUser(context);
                          if (!reauth) return;
                        }
                        final result = await fireBaseRepo.updateUser(
                          updatedUser,
                          isUpdatingPassword ? passwordController.text : "",
                        );
                        if (!mounted) return;
                        if (result == null) {
                          setState(() {
                            error = "이미 사용 중인 닉네임입니다";
                          });
                        } else {
                          setState(() {
                            error = "";
                            // Update local user state
                            currentUser = updatedUser;
                          });
                          if (isUpdatingName) nameController.clear();
                          if (isUpdatingPassword) passwordController.clear();
                          if (isUpdatingPhone) phoneController.clear();
                          if (isUpdatingBio) bioController.clear();

                          String successMessage = "";
                          List<String> updated = [];
                          if (isUpdatingName) updated.add("닉네임");
                          if (isUpdatingPassword) updated.add("비밀번호");
                          if (isUpdatingPhone) updated.add("전화번호");
                          if (isUpdatingBio) updated.add("소개");
                          if (updated.isNotEmpty) {
                            successMessage =
                                updated.join(", ") + "가 성공적으로 업데이트되었습니다";
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                successMessage,
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          error = "업데이트 중 오류가 발생했습니다: " + e.toString();
                        });
                      }
                    },
                    style: TextStyles.abeezee14px400wW.copyWith(
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
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
