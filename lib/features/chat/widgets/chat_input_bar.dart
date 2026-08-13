import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

const _kBgColor = Color(0xFFF2F2F2);
const _kInputBg = Color(0xFFE8E8E8);
const _kSendActive = Color(0xFF1A1A1A);

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final XFile? pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onSend;
  final bool autofocus;
  final bool isUploading;

  const InputBar({
    super.key,
    required this.controller,
    required this.pickedImage,
    required this.onPickImage,
    required this.onSend,
    this.autofocus = false,
    this.isUploading = false,
  });

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: _kBgColor,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 40.h),
                decoration: BoxDecoration(
                  color: _kInputBg,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : onPickImage,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 20.sp,
                          color: isUploading ? Colors.grey[300] : Colors.grey[500],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (_isDesktopOrWeb && !isUploading) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter) {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                return KeyEventResult.ignored; // Add a new line
                              } else {
                                final text = controller.text.trim();
                                if (text.isNotEmpty || pickedImage != null) {
                                  onSend();
                                }
                                return KeyEventResult.handled; // Prevent default new line
                              }
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: controller,
                          enabled: !isUploading,
                          autofocus: autofocus,
                          maxLines: 4,
                          minLines: 1,
                          style: TextStyle(fontSize: 14.sp, color: Colors.black),
                          decoration: InputDecoration(
                            hintText: '메시지 입력',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(
                              right: 12.w,
                              top: 10.h,
                              bottom: 10.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final bool showButton =
                    value.text.trim().isNotEmpty || pickedImage != null || isUploading;

                return AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child:
                      showButton
                          ? Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: GestureDetector(
                              onTap: isUploading ? null : onSend,
                              child: Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: const BoxDecoration(
                                  color: _kSendActive,
                                  shape: BoxShape.circle,
                                ),
                                child: isUploading
                                    ? Center(
                                        child: SizedBox(
                                          width: 18.w,
                                          height: 18.w,
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 20.sp,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
