import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../pages/home_page.dart';

class Less4PrevotePage extends StatefulWidget {
  const Less4PrevotePage({Key? key}) : super(key: key);

  @override
  _PrevotePageState createState() => _PrevotePageState();
}

class _PrevotePageState extends State<Less4PrevotePage> {
  int _friendCount = 0;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(15.sp, 10, 0, 0),
              child: Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.fromLTRB(0, 54, 0, 0),
                child: Text(
                  'Flirt',
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Text(
                '익명 투표는 친구가\n 4명 이상이어야 진행 할 수 있어요',
                style: TextStyle(
                  fontSize: 23.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20, 30, 20, 50),
              child: Animate(
                child: Image.asset('assets/juicy-woman-is-looking-through-resumes.gif'),
              ).fadeIn(),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(70, 10, 70, 20),
              child: Text(
                '친구 추가를 해도 상대방에게 알려지지 않아요\u{1F60E}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(selectedIndex: 3),
                  ),
                );
              },
              child: Text(
                '친구 추가하러 가기',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
