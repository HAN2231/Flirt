import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../chat/chat_page.dart';

class ChatBottomPage extends StatefulWidget {
  final String receiverEmail;
  final String voterId;
  final String hint1;
  final String hint2;
  final String hint3;
  final String greeting;
  final int currentPoints;
  final String voteId; // 추가된 voteId

  const ChatBottomPage({
    Key? key,
    required this.receiverEmail,
    required this.voterId,
    required this.hint1,
    required this.hint2,
    required this.hint3,
    required this.greeting,
    required this.currentPoints,
    required this.voteId, // 추가된 voteId
  }) : super(key: key);

  @override
  _ChatBottomPageState createState() => _ChatBottomPageState();
}

class _ChatBottomPageState extends State<ChatBottomPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isAnimating = false;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _points = widget.currentPoints; // 초기 포인트 값을 설정합니다.
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startAnimationAndNavigate() {
    setState(() {
      _isAnimating = true;
    });
    _animationController.forward().then((_) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'points': _points - 100}).then((_) {
        Navigator.of(context).pop(); // 바텀시트 내리기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              voteId: widget.voteId, // 추가된 voteId
              receiverEmail: widget.receiverEmail,
              voterId: widget.voterId,
              hint1: widget.hint1,
              hint2: widget.hint2,
              hint3: widget.hint3,
              greeting: widget.greeting,
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '채팅을 시작하시겠습니까?',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '대화 시작 시 ',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
                ),
                Image.asset(
                  'assets/juicy-gold-coin.png', // coin 이미지 경로
                  width: 24.w,
                  height: 24.h,
                ),
                Text(
                  '100 차감 됩니다.',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _isAnimating
                ? AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '현재 나의 ',
                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                    ),
                    Image.asset(
                      'assets/juicy-gold-coin.png', // coin 이미지 경로
                      width: 24.w,
                      height: 24.h,
                    ),
                    Text(
                      ' : ${(_points - (100 * _animation.value)).toInt()}',
                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                    ),
                  ],
                );
              },
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '현재 나의 ',
                  style: TextStyle(fontSize: 18.sp, color: Colors.black),
                ),
                Image.asset(
                  'assets/juicy-gold-coin.png', // coin 이미지 경로
                  width: 24.w,
                  height: 24.h,
                ),
                Text(
                  ' : $_points',
                  style: TextStyle(fontSize: 18.sp, color: Colors.black),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                if (_points >= 100) {
                  _startAnimationAndNavigate();
                } else {
                  // 포인트 부족 안내 메시지 추가
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('포인트가 부족합니다.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _points >= 100 ? Colors.blue : Colors.grey, // 100 포인트 이상일 때만 파란색
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 30.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                minimumSize: Size(double.infinity, 40.h),
              ),
              child: Text(
                '채팅하기',
                style: TextStyle(fontSize: 18.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 15.h),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
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
