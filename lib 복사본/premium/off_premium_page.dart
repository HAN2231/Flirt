import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OffPremiumPage extends StatefulWidget {
  @override
  _OffPremiumPageState createState() => _OffPremiumPageState();
}

class _OffPremiumPageState extends State<OffPremiumPage> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false; // 결제 진행 상태를 추적하기 위한 변수
  bool _isSubscribed = false; // 구독 상태를 추적하기 위한 변수

  final List<String> descriptions = [
    '투표자 초성 엿보기',
    '포인트 2배',
    '무제한 채팅 하기',
  ];

  final List<String> imagePaths = [
    'assets/juicy-pink-magnifier.png',
    'assets/juicy-gold-coin.png',
    'assets/juicy-envelope-with-heart.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    setState(() {
      _isLoading = true; // 로딩 상태로 변경
    });

    // 결제 API 호출 또는 기타 결제 로직 수행
    // 이 예제에서는 2초 지연 후 결제가 성공했다고 가정

    await Future.delayed(Duration(seconds: 2));

    // Firestore에서 현재 사용자의 premium 필드를 on으로 수정
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'premium': 'on',
      });
    }

    setState(() {
      _isLoading = false; // 로딩 상태 해제
      _isSubscribed = true; // 구독 상태로 변경
    });

    await Future.delayed(Duration(seconds: 1));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400.h,
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
                  'Flirt Premium으로',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '누가 보냈는지 확인해보세요',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              margin: EdgeInsets.only(top: 15),
              height: 140.h,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: descriptions.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Image.asset(imagePaths[index], height: 100.h),
                      SizedBox(height: 10.h),
                      Text(
                        descriptions[index],
                        style: TextStyle(fontSize: 17.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            Center(
              child: DotsIndicator(
                dotsCount: descriptions.length,
                position: _currentPage.toDouble(),
                decorator: DotsDecorator(
                  activeColor: Colors.blue,
                  size: Size.square(8.0),
                  activeSize: Size(18.0, 8.0),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 13.h),
            Text('￦990/일주일',
                style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            _isLoading
                ? Container(
                margin: EdgeInsets.all(14.5),
                child: const CircularProgressIndicator())
                : Container(
              child: ElevatedButton(
                onPressed: _isSubscribed ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(
                      vertical: 15.h, horizontal: 30.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  minimumSize: Size(double.infinity, 40.h),
                ),
                child: _isSubscribed
                    ? Image.asset('assets/juicy-check-mark-in-a-circle.png',height: 28,)
                    : Text(
                  '구독하기',
                  style:
                  TextStyle(fontSize: 18.sp, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // BottomSheet 닫기
              },
              child: Text(
                '다음에',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}