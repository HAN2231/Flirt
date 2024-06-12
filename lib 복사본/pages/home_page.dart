import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logintest/pages/menus/cardroom_page.dart';
import 'package:logintest/vote/waiting_vote_page.dart';
import 'menus/profile_page.dart';
import 'menus/reels_page.dart';
import 'menus/vote_page.dart';

class HomePage extends StatefulWidget {
  final bool fromPostVotePage;
  final int selectedIndex;
  final int? secondsRemaining; // 추가

  const HomePage({Key? key, this.fromPostVotePage = false, this.selectedIndex = 0, this.secondsRemaining = 3600}) : super(key: key); // 기본값 3600초

  @override
  State<HomePage> createState() => _HomePageState();
}

final user = FirebaseAuth.instance.currentUser!;

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late int _selectedIndex;
  late bool _fromPostVotePage;
  late SharedPreferences _prefs;
  Timer? _timer;
  int _secondsRemaining = 3600;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.selectedIndex;
    _fromPostVotePage = widget.fromPostVotePage;
    _secondsRemaining = widget.secondsRemaining ?? 3600; // 추가
    _initSharedPreferences();
    if (_fromPostVotePage) {
      _startTimer();
    }
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey('timerValue')) {
      setState(() {
        _secondsRemaining = _prefs.getInt('timerValue') ?? 3600;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
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
          _onTimerFinish();
        }
      });
    });
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onTimerFinish() {
    setState(() {
      _fromPostVotePage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          if (_fromPostVotePage && _selectedIndex == 0) // 오직 VotePage에서만 표시
            Stack(
              children: [
                _KeepAliveWrapper(child: VotePage()),
                Positioned.fill(
                  child: WaitingVotePage(
                    secondsRemaining: _secondsRemaining,
                    onTimerFinish: _onTimerFinish,
                  ),
                ),
              ],
            )
          else
            const _KeepAliveWrapper(child: VotePage()),
          const _KeepAliveWrapper(child: CardRoomPage()),
          const _KeepAliveWrapper(child: ReelsPage()),
          const _KeepAliveWrapper(child: ProfilePage()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)), // 라인효과
        ),
        child: CupertinoTabBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _navigateBottomBar,
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.hand_thumbsup,
                  color: _selectedIndex == 0 ? Colors.blueGrey : null),
              activeIcon: Icon(CupertinoIcons.hand_thumbsup_fill, color: Colors.black),
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.tray_full,
                  color: _selectedIndex == 1 ? Colors.blueGrey : null),
              activeIcon: Icon(CupertinoIcons.tray_full_fill, color: Colors.black),
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.compass,
                  color: _selectedIndex == 2 ? Colors.blueGrey : null),
              activeIcon: Icon(CupertinoIcons.compass_fill, color: Colors.black),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline,
                  color: _selectedIndex == 3 ? Colors.blueGrey : null),
              activeIcon: Icon(Icons.person, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  __KeepAliveWrapperState createState() => __KeepAliveWrapperState();
}

class __KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}