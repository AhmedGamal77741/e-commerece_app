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
  MyUser myUser;
  UserInfoContainer({super.key, required this.myUser});

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

  Future<bool> _reauthenticateUser(BuildContext context) async {
    bool success = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final TextEditingController reauthController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('비밀번호 재확인', style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '비밀번호를 변경하려면 현재 비밀번호를 입력하세요.',
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 16),
              UnderlineTextField(
                controller: reauthController,
                hintText: '현재 비밀번호',
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                validator:
                    (val) => val == null || val.isEmpty ? '비밀번호를 입력하세요' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                reauthController.dispose();
              },
              child: Text('취소', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
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
                      SnackBar(content: Text('재인증 실패: 비밀번호를 확인하세요.')),
                    );
                  }
                } finally {
                  reauthController.dispose();
                }
              },
              child: Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return success;
  }

  @override
  void dispose() {
    // Clean up controllers
    passwordController.dispose();
    nameController.dispose();
    bioController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: ColorsManager.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: ColorsManager.primary100),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('userId', style: TextStyles.abeezee16px400wPblack),

              verticalSpace(20),

              // userId field
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: ColorsManager.primary100,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  widget.myUser.tag ?? '',
                  style: TextStyles.abeezee16px400wPblack.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),

              verticalSpace(20),

              // Avatar Row
              Text('닉네임', style: TextStyles.abeezee16px400wPblack),

              verticalSpace(20),

              // Name field
              UnderlineTextField(
                controller: nameController,
                hintText: widget.myUser.name,
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  // Skip validation if empty - we'll handle this separately
                  if (val!.isEmpty) return null;
                  if (val.length > 30) return '이름이 너무 깁니다';
                  return null;
                },
              ),
              verticalSpace(20),

              // Avatar Row
              Text('User bio', style: TextStyles.abeezee16px400wPblack),

              verticalSpace(20),

              // Name field
              UnderlineTextField(
                controller: bioController,
                hintText: widget.myUser.bio ?? '',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  // Skip validation if empty - we'll handle this separately
                  if (val!.isEmpty) return null;
                  if (val.length > 30) return '이름이 너무 깁니다';
                  return null;
                },
              ),
              verticalSpace(20),
              Text('전화번호', style: TextStyles.abeezee16px400wPblack),
              verticalSpace(20),

              UnderlineTextField(
                controller: phoneController,
                hintText: widget.myUser.phoneNumber ?? '',
                obscureText: false,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val!.isEmpty) return null;
                  // Korean phone number: 010-xxxx-xxxx or 010xxxxxxxx
                  final koreanReg = RegExp(r'^(01[016789])-?\d{3,4}-?\d{4}$');
                  if (!koreanReg.hasMatch(val)) {
                    return '유효한 한국 전화번호를 입력하세요';
                  }
                  return null;
                },
              ),
              verticalSpace(20),

              // Password and submit button
              Text('비밀번호', style: TextStyles.abeezee16px400wPblack),
              Row(
                children: [
                  const Spacer(),
                  BlackTextButton(
                    txt: '완료',
                    func: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (nameController.text.isEmpty &&
                          passwordController.text.isEmpty) {
                        setState(() {
                          error = "이름 또는 비밀번호를 입력해 주세요";
                        });
                        return;
                      }
                      final isUpdatingName = nameController.text.isNotEmpty;
                      final isUpdatingPassword =
                          passwordController.text.isNotEmpty;
                      final isUpdatingPhone = phoneController.text.isNotEmpty;
                      final isUpdatingBio = bioController.text.isNotEmpty;

                      if (isUpdatingName) {
                        widget.myUser.name = nameController.text;
                      }

                      if (isUpdatingPhone) {
                        widget.myUser.phoneNumber = phoneController.text;
                      }
                      if (isUpdatingBio) {
                        widget.myUser.bio = bioController.text;
                      }
                      try {
                        // If updating password, require re-authentication
                        if (isUpdatingPassword) {
                          final reauth = await _reauthenticateUser(context);
                          if (!reauth) return;
                        }
                        final result = await fireBaseRepo.updateUser(
                          widget.myUser,
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
                          });
                          if (isUpdatingName) nameController.clear();
                          if (isUpdatingPassword) passwordController.clear();
                          if (isUpdatingPhone) phoneController.clear();
                          if (isUpdatingBio) bioController.clear();

                          String successMessage;
                          if (isUpdatingName && isUpdatingPassword) {
                            successMessage = "닉네임과 비밀번호가 성공적으로 업데이트되었습니다";
                          } else if (isUpdatingName) {
                            successMessage = "닉네임이 성공적으로 업데이트되었습니다";
                          } else {
                            successMessage = "비밀번호가 성공적으로 업데이트되었습니다";
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(successMessage)),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          error = "업데이트 중 오류가 발생했습니다: " + e.toString();
                        });
                      }
                    },
                    style: TextStyles.abeezee14px400wW,
                  ),
                ],
              ),

              // Password field
              UnderlineTextField(
                controller: passwordController,
                hintText: '영문,숫자 조합',
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                validator: (val) {
                  // Skip validation if empty - we'll handle this separately
                  if (val!.isEmpty) return null;
                  if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(val)) {
                    return '유효한 비밀번호를 입력해 주세요';
                  }
                  return null;
                },
              ),

              if (error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
