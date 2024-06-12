import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnPremiumPage extends StatefulWidget {
  @override
  _OnPremiumPage createState() => _OnPremiumPage();
}

class _OnPremiumPage extends State<OnPremiumPage> {
  late PageController _pageController;

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

  final List<String>  explainations= [
    '초성을 확인하고 유추해보세요',
    '더 많은 포인트를 얻어보세요',
    '채팅 제한 없이 소통 해보세요',
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140.w,
                  height: 140.h,
                  child: Image.asset("assets/ef.png"),
                ),
                Text(
                  'Flirt Premium 가입을 축하드립니다!',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 7.h),
                Text(
                  '다음의 혜택들을 누려보세요',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15.sp),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Column(
              children: List.generate(imagePaths.length, (index) {
                return Container(
                  margin: EdgeInsets.all(15.w),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        margin: EdgeInsets.only(right: 15.w), // 오른쪽 마진을 추가하여 이미지와 텍스트 사이에 공간을 둠
                        child: Image.asset(imagePaths[index], height: 40.h),
                      ),
                       Column(
                         children: [
                           Container(
                              child: Text(
                                descriptions[index],
                                style: TextStyle(fontSize: 17.sp,fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left, // 텍스트를 왼쪽 정렬
                              ),
                            ),
                            Container(
                              child: Text(
                                explainations[index],
                                style: TextStyle(fontSize: 16.sp,color: Colors.grey[600]),
                                textAlign: TextAlign.left, // 텍스트를 왼쪽 정렬
                              ),
                            ),
                         ],
                       ),

                    ],
                  ),
                );
              }),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // BottomSheet 닫기
              },
              child: Text(
                '혜택 누리러 가기',
                style: TextStyle(fontSize: 13.sp, color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
