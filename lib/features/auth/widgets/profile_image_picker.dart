import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';

class ProfileImagePicker extends StatelessWidget {
  final XFile? selectedImage;
  final ValueChanged<XFile?> onImagePicked;

  const ProfileImagePicker({
    super.key,
    required this.selectedImage,
    required this.onImagePicked,
  });

  Future<void> _pickImage() async {
    try {
      final XFile? image = await ImagePickerHelper.pickImage();
      if (image != null) {
        onImagePicked(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: selectedImage != null
            ? ClipOval(
                child: Image.file(
                  File(selectedImage!.path),
                  height: 80.h,
                  width: 80.h,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                height: 80.h,
                width: 80.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person, 
                  size: 50.h, 
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
