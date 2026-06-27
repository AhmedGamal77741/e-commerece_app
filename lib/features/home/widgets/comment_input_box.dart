import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';
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

  Future<void> _pickImage() async {
    final picked = await ImagePickerHelper.pickImage();
    if (picked != null) setState(() => _pickedImage = picked);
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
        if (_pickedImage != null)
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: kIsWeb
                      ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _pickedImage = null),
                  ),
                ),
              ],
            ),
          ),
        InputBar(
          controller: _commentController,
          pickedImage: _pickedImage,
          onPickImage: _pickImage,
          onSend: () async {
            final text = _commentController.text.trim();
            if (text.isEmpty && _pickedImage == null) return;

            File? imageFile;
            Uint8List? imageBytes;
            
            if (_pickedImage != null) {
              if (kIsWeb) {
                imageBytes = await _pickedImage!.readAsBytes();
              } else {
                imageFile = File(_pickedImage!.path);
              }
            }
            
            try {
              await widget.onSubmit(text, imageFile: imageFile, imageBytes: imageBytes);
              _commentController.clear();
              if (mounted) setState(() => _pickedImage = null);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 추가에 실패했습니다: $e')));
            }
          },
        ),
      ],
    );
  }
}
