import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/home/data/home_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildPostActions(DocumentSnapshot post) {
  final data = post.data() as Map<String, dynamic>;
  final currentUser = FirebaseAuth.instance.currentUser;

  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10.w,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4.w,
        children: [
          InkWell(
            onTap: () {
              toggleLike(post);
            },
            child: SizedBox(
              width: 22.w,
              height: 22.h,
              child: ImageIcon(
                AssetImage(
                  data['likedBy']?.contains(currentUser!.uid) ?? true
                      ? "assets/icon=like,status=off (1).png"
                      : "assets/icon=like,status=off.png",
                ),
                color:
                    data['likedBy']?.contains(currentUser!.uid) ?? true
                        ? Colors.red
                        : Colors.black,
              ),
            ),
          ),
          SizedBox(
            width: 25,
            height: 22,
            child: Text(
              data['likes'].toString(),
              style: TextStyle(
                color: const Color(0xFF343434),
                fontSize: 14,
                fontFamily: 'ABeeZee',
                fontWeight: FontWeight.w400,
                height: 1.40,
              ),
            ),
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          InkWell(
            onTap: () {},
            child: SizedBox(
              width: 22.w,
              height: 22.h,
              child: ImageIcon(AssetImage("assets/icon=comment.png")),
            ),
          ),
          SizedBox(
            width: 25,
            height: 22,
            child: Text(
              data['comments'].toString(),
              style: TextStyle(
                color: const Color(0xFF343434),
                fontSize: 14,
                fontFamily: 'ABeeZee',
                fontWeight: FontWeight.w400,
                height: 1.40,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
