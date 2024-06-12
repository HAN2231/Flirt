import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logintest/vote/dm_room_page.dart';
import 'package:logintest/vote/ranking_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/message_service.dart';


class More4PrevotePage extends StatefulWidget {
  const More4PrevotePage({Key? key}) : super(key: key);

  @override
  _PrevotePageState createState() => _PrevotePageState();
}

class _PrevotePageState extends State<More4PrevotePage> {
  int _friendCount = 0;
  double _position = 0.0;
  bool _isGoingUp = true;
  int _unreadMessageCount = 0;

  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _setInitialFriendCount();
    _startAnimation();
    _subscribeToUnreadMessageCount(); // 메시지 수 구독
  }

  @override
  void dispose() {
    super.dispose();
    MessageService().dispose(); // 구독 해제
  }

  void _setInitialFriendCount() {
    setState(() {
      _friendCount = 4;
    });
  }

  void _startAnimation() {
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          _position = _isGoingUp ? -10.0 : 10.0;
          _isGoingUp = !_isGoingUp;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _subscribeToUnreadMessageCount() {
    MessageService().unreadMessageCountStream.listen((count) {
      setState(() {
        _unreadMessageCount = count;
      });
    });
    MessageService().subscribeToChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil
    ScreenUtil.init(
      context,
      designSize: Size(360, 690), // 디자인 기준 크기
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          RankingPage(),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center, // 중앙 정렬
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.fromLTRB(15, 64, 15, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.chart_bar_alt_fill, size: 24.sp),
                        onPressed: () {
                          _pageController.animateToPage(0,
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut);
                        },
                      ),
                      Text(
                        'Flirt',
                        style: TextStyle(
                          fontFamily: 'continuous',
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(CupertinoIcons.mail_solid, size: 24.sp),
                            onPressed: () {
                              _pageController.animateToPage(2,
                                  duration: Duration(milliseconds: 400),
                                  curve: Curves.easeInOut);
                            },
                          ),
                          if (_unreadMessageCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_unreadMessageCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(14, 19, 229, 0.3), // 배경 색상 설정
                    border: Border.all(
                      color: Colors.black, // 테두리 색상
                      width: 2.0, // 테두리 두께
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _pageController.animateToPage(
                        0,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                      // 버튼이 눌렸을 때 수행할 작업 추가
                    },
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all(Colors.transparent),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      )),
                      padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                      elevation: MaterialStateProperty.all(0),
                      shadowColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '이번 주 인기투표가 오픈되었어요!',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 0.005.sh),
                          Text(
                            '최종 인기투표 결과 확인하기',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  child: Text(
                    '10개의 질문을 준비해 두었어요.',
                    style: TextStyle(
                      fontFamily: 'jalnan',
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Text(
                    '투표를 시작할 수 있어요!',
                    style: TextStyle(
                      fontFamily: 'jalnan',
                      fontSize: 27.sp,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  height: 320.h,
                  child: Animate(
                    child: Image.asset(
                        'assets/juicy-hands-holding-gadgets-with-social-media.png'),
                  ).fadeIn(),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  transform: Matrix4.translationValues(0.0, _position, 0.0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Text(
                      '위로 밀어서 투표 시작하기!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'jalnan',
                        fontSize: 20.sp,
                        color: Color.fromRGBO(
                            14, 19, 229, 0.8), // 텍스트 색상을 파란색으로 지정
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DmRoomPage(),
        ],
      ),
    );
  }
}