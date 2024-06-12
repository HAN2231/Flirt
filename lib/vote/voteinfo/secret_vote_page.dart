import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecretVotePage extends StatefulWidget {
  @override
  _SecretVotePage createState() => _SecretVotePage();
}

class _SecretVotePage extends State<SecretVotePage> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '시크릿 투표는',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '상대방을 알 수 없어요',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5.h,),
                Text(
                  'Premium 구독자도 예외는 없습니다.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
                margin: EdgeInsets.symmetric(vertical: 18.h, horizontal: 90.w),
                child: Image.asset('assets/juicy-keyhole-shield.png')),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // BottomSheet 닫기
              },
              child: Text(
                '다음에',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[350]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
