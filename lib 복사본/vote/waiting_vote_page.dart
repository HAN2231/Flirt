import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logintest/make_vote_page.dart';
import 'package:logintest/vote/dm_room_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logintest/vote/ranking_page.dart';
import '../model/message_service.dart';

class WaitingVotePage extends StatefulWidget {
  final VoidCallback onTimerFinish;
  final int secondsRemaining; // 타이머 시간을 받기 위해 추가

  WaitingVotePage(
      {Key? key, required this.onTimerFinish, required this.secondsRemaining})
      : super(key: key);

  @override
  _WaitingVotePageState createState() => _WaitingVotePageState();
}

class _WaitingVotePageState extends State<WaitingVotePage>
    with WidgetsBindingObserver {
  late SharedPreferences _prefs;
  Timer? _timer;
  late int _secondsRemaining; // 타이머 시간을 초기화하기 위해 수정
  DateTime? _pausedTime;
  final PageController _pageController = PageController(initialPage: 1);
  bool _showButtons = true; // Added to control the visibility of buttons
  double _position = 0.0;
  bool _isGoingUp = true;
  int _unreadMessageCount = 0; // 추가

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.secondsRemaining; // 타이머 시간 초기화
    _initSharedPreferences().then((_) {
      _startTimer();
    });
    _startAnimation();
    MessageService().unreadMessageCountStream.listen((count) {
      setState(() {
        _unreadMessageCount = count;
      });
    });
    MessageService().subscribeToChatRooms();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey('timerValue')) {
      setState(() {
        _secondsRemaining = _prefs.getInt('timerValue') ?? widget.secondsRemaining;
      });
    } else {
      await _prefs.setInt('timerValue', widget.secondsRemaining);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
    MessageService().dispose(); // 추가
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedTime != null) {
      final diff = DateTime.now().difference(_pausedTime!).inSeconds;
      setState(() {
        _secondsRemaining -= diff;
        _prefs.setInt('timerValue', _secondsRemaining);
      });
      _pausedTime = null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _prefs.setInt('timerValue', _secondsRemaining);
        } else {
          _timer?.cancel();
          _prefs.remove('timerValue');
          widget.onTimerFinish();
        }
      });
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

  void _showMakeQuestionPage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: MakeVotePage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index) {
          setState(() {
            _showButtons = index == 0;
          });
        },
        children: [
          RankingPage(),
          _buildTimerPage(minutes, seconds),
          DmRoomPage(),
        ],
      ),
    );
  }

  Widget _buildTimerPage(int minutes, int seconds) {
    return SingleChildScrollView(
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
                  1,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
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
                      '최종 인기투표 결과 확인하기 >',
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
            margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '다음 투표까지 남은시간: ',
                  style: TextStyle(
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 30.sp),
                SizedBox(width: 8.w),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            width: 600,
            child: Animate(
              child: Image.asset(
                'assets/juicy-man-delivers-a-parcel-on-a-scooter.gif',
              ),
            ).fadeIn(), // 애니메이션 효과 추가
          ),
          Container(
            margin: EdgeInsets.fromLTRB(15, 10, 15, 10),
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey,),
            ),
            child: ElevatedButton(
              onPressed: () => _showMakeQuestionPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '내가 직접 투표 질문지를 만들 수도 있어요!',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(14, 19, 229, 1.0),
                      ),
                    ),
                    SizedBox(height: 0.009.sh),
                    Text(
                      '질문지로 선정 되면 포인트도 드립니다!',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Color.fromRGBO(14, 19, 229, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}