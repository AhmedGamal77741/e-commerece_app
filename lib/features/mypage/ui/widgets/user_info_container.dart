import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/black_text_button.dart';
import 'package:ecommerece_app/core/widgets/underline_text_filed.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  String imgUrl = "";
  String error = '';
  final fireBaseRepo = FirebaseUserRepo();

  MyUser? currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start listening to posts as before
    Provider.of<PostsProvider>(context, listen: false).startListening();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await FirebaseUserRepo().user.first;
      if (!mounted) return;
      setState(() {
        currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading user: $e');
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    passwordController.dispose();
    nameController.dispose();
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
              // Avatar Row
              Text('닉네임', style: TextStyles.abeezee16px400wPblack),

              verticalSpace(20),

              // Name field
              UnderlineTextField(
                controller: nameController,
                hintText: '팽이마켓',
                obscureText: false,
                keyboardType: TextInputType.name,
                validator: (val) {
                  if (val!.isEmpty) return '이 필드를 입력해 주세요';
                  if (val.length > 30) return '이름이 너무 깁니다';
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

                      final myUser = MyUser(
                        userId: currentUser!.userId,
                        email: currentUser!.email,
                        name: nameController.text,
                        url: imgUrl,
                      );

                      final result = await fireBaseRepo.updateUser(
                        myUser,
                        passwordController.text,
                      );

                      if (!mounted) return;
                      if (result == null) {
                        setState(() {
                          error = "이미 사용 중인 이메일입니다";
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
                  if (val!.isEmpty) return '이 필드를 작성해 주세요';
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
