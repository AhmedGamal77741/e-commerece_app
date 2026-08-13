import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';
import 'package:ecommerece_app/core/helpers/image_upload_helper.dart';
import 'package:ecommerece_app/features/chat/widgets/chat_input_bar.dart';

class CommentInputBox extends StatefulWidget {
  final Future<void> Function(String text, {File? imageFile, Uint8List? imageBytes}) onSubmit;

  const CommentInputBox({super.key, required this.onSubmit});

  @override
  State<CommentInputBox> createState() => _CommentInputBoxState();
}

class _CommentInputBoxState extends State<CommentInputBox> {
  final TextEditingController _commentController = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isUploading = false;
  bool _isPreparingImage = false;

  Future<void> _pickImage() async {
    if (_isUploading || _isPreparingImage) return;
    final picked = await ImagePickerHelper.pickImage();
    if (picked != null) {
      if (mounted) {
        setState(() {
          _pickedImage = picked;
          _pickedImageBytes = null;
          _isPreparingImage = true;
        });
      }
      try {
        final rawBytes = await picked.readAsBytes();
        final previewBytes = await ImageUploadHelper.preparePreviewBytes(rawBytes, picked.name);
        if (mounted) {
          setState(() {
            _pickedImageBytes = previewBytes;
            _isPreparingImage = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _pickedImage = null;
            _pickedImageBytes = null;
            _isPreparingImage = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_pickedImage != null || _isPreparingImage)
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Stack(
              children: [
                if (_isPreparingImage)
                  Container(
                    height: 160.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.black54,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            '이미지 로딩 중...',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: _pickedImageBytes != null
                        ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                        : kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: _pickedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return const SizedBox.shrink();
                                },
                              )
                            : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                  ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            '업로드 중...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isUploading)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _pickedImage = null;
                        _pickedImageBytes = null;
                        _isPreparingImage = false;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        InputBar(
          controller: _commentController,
          pickedImage: _pickedImage,
          isUploading: _isUploading || _isPreparingImage,
          onPickImage: _pickImage,
          onSend: () async {
            if (_isUploading || _isPreparingImage) return;
            final text = _commentController.text.trim();
            if (text.isEmpty && _pickedImage == null) return;

            File? imageFile;
            Uint8List? imageBytes = _pickedImageBytes;
            
            if (_pickedImage != null && imageBytes == null) {
              if (kIsWeb) {
                imageBytes = await _pickedImage!.readAsBytes();
              } else {
                imageFile = File(_pickedImage!.path);
              }
            }
            
            if (mounted) setState(() => _isUploading = true);
            
            try {
              await widget.onSubmit(text, imageFile: imageFile, imageBytes: imageBytes);
              _commentController.clear();
              if (mounted) {
                setState(() {
                  _pickedImage = null;
                  _pickedImageBytes = null;
                  _isUploading = false;
                  _isPreparingImage = false;
                });
              }
            } catch (e) {
              if (mounted) setState(() => _isUploading = false);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('댓글 추가에 실패했습니다: $e')),
              );
            }
          },
        ),
      ],
    );
  }
}
