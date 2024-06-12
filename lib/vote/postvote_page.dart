import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/home_page.dart';

class PostvotePage extends StatefulWidget {
  final int remainingQuestions;
  final int earnedPoints;

  const PostvotePage({
    Key? key,
    required this.remainingQuestions,
    required this.earnedPoints,
  }) : super(key: key);

  @override
  _PostvotePageState createState() => _PostvotePageState();
}

class _PostvotePageState extends State<PostvotePage> {
  int _currentPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentPoints();
  }

  Future<void> _fetchCurrentPoints() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
        userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentPoints = userData['points'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      int totalPoints = _currentPoints + widget.earnedPoints;

      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          'assets/juicy-gold-coin.png', // 포인트 아이콘 이미지 경로
                          width: 30.w,
                          height: 30.h,
                        ),
                        SizedBox(width: 10.w),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$_currentPoints',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: ' +${widget.earnedPoints}',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  color: Colors.green, // 변경할 부분에 다른 색 적용
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                      children: <TextSpan>[
                        TextSpan(text: '투표하지 않은 질문이 '),
                        TextSpan(
                          text: '${widget.remainingQuestions}',
                          style: TextStyle(color: Colors.black), // 여기에서 색상 변경
                        ),
                        TextSpan(text: '개 있어요!'),
                      ],
                    ),
                  ),
                  Image.asset(
                    "assets/juicy-girl-sending-messages-from-her-phone.gif",
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '익명으로 마음 표현하기 성공했어요!',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '투표를 마치시겠습니까?',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            fromPostVotePage: true,
                            secondsRemaining: 3600, // 1시간 타이머 설정
                          ),
                        ),
                      );
                    },
                    child: Text(
                      '투표 마치기',
                      style: TextStyle(fontSize: 20.sp, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.blue,
                      padding:EdgeInsets.symmetric(
                          horizontal: 80.w, vertical: 10.h
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      )
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}