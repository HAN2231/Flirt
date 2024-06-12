import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logintest/components/greeting_data.dart';
import 'package:logintest/vote/4less_prevote_page.dart';
import 'package:logintest/vote/postvote_page.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../api/firebase_api.dart';
import '../../model/message_service.dart';
import '../../vote/4more_prevote_page.dart';
import '../../vote/dm_room_page.dart';
import '../../vote/ranking_page.dart';

class VotePage extends StatefulWidget {
  final bool fromPostVotePage;

  const VotePage({Key? key, this.fromPostVotePage = false}) : super(key: key);

  @override
  _VotePageState createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final PageController _pageController = PageController();
  final int _maxPageCount = 12; // 최대 페이지 수 수정
  final List<String> _greetings = [];
  final Map<int, List<String>> _optionsMap = {};
  final Map<int, bool> _voteCompleted = {};
  final Map<int, bool> _pageSecretMode = {};
  final List<Color?> _pageBackgroundColors = [];
  final Map<int, String> _selectedUserForVote = {};
  int _secretModeCount = 1;

  late StreamSubscription<QuerySnapshot> _friendCountSubscription;
  late StreamSubscription<QuerySnapshot> _chatRoomsSubscription;
  List<StreamSubscription<QuerySnapshot>> _messageSubscriptions = [];
  int _shuffleCount = 3;
  bool _isGoingUp = true;
  double _position = 0.0;
  int _friendCount = 0;
  int _completedVotesCount = 0; // 완료된 투표 수
  int _earnedPoints = 0; // 이번 투표로 얻은 포인트

  bool _showButtons = true;
  double _lastOffset = 0;
  int _currentPageIndex = 0;
  int _unreadMessageCount = 0; // 안 읽은 메시지 개수를 저장할 변수

  bool _isInitialized = false; // 초기화 여부 확인

  @override
  void initState() {
    super.initState();
    _initializeVoteCompletion();
    _initializePageColors();
    _preloadGreetings();
    _checkInitialFriendCount(); // 친구 수 초기 확인
    _pageController.addListener(_handleScroll);
    _subscribeToUnreadMessageCount(); // 안 읽은 메시지 개수 가져오기
  }

  @override
  void dispose() {
    _pageController.removeListener(_handleScroll);
    _pageController.dispose();
    _friendCountSubscription.cancel();
    _chatRoomsSubscription.cancel();
    for (var subscription in _messageSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
    MessageService().dispose(); // 추가
  }

  void _initializeVoteCompletion() {
    for (int i = 0; i < _maxPageCount; i++) {
      _voteCompleted[i] = false;
      _pageSecretMode[i] = false; // 각 페이지의 시크릿 모드 초기화
    }
  }

  void _initializePageColors() {
    _pageBackgroundColors.addAll(
      List<Color?>.generate(_maxPageCount, (index) => _getPastelColor()),
    );
  }

  void _preloadGreetings() {
    Set<int> selectedIndices = {};
    while (selectedIndices.length < _maxPageCount - 1) {
      int randomIndex = Random().nextInt(greetingData.length);
      selectedIndices.add(randomIndex);
    }

    for (int index in selectedIndices) {
      String randomQuestion = greetingData.keys.elementAt(index);
      _greetings.add(randomQuestion);
    }
  }

  Future<void> _checkInitialFriendCount() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .get();
    setState(() {
      _friendCount = friendsSnapshot.size;
      _isInitialized = true; // 초기화 완료 표시
      if (_friendCount >= 4) {
        _subscribeToFriendCount(); // 친구 수 변경 추적 시작
        _preloadOptions();
        _startAnimation();
      }
    });
  }

  Future<void> _subscribeToFriendCount() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _friendCountSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .listen((snapshot) async {
      int newFriendCount = snapshot.size;
      if ((newFriendCount < 4 && _friendCount >= 4) ||
          (newFriendCount >= 4 && _friendCount < 4)) {
        print('친구 수 변화 감지: $newFriendCount');
        _friendCount = newFriendCount;
        await _preloadOptions();
        _initializeVoteCompletion();
        _initializePageColors();
        _preloadGreetings();
        setState(() {});
      } else {
        setState(() {
          _friendCount = newFriendCount;
        });
      }
    });
  }

  Future<void> _preloadOptions() async {
    for (int i = 1; i < _maxPageCount - 1; i++) {
      List<String> friendIds = await _fetchRandomFriends();
      _optionsMap[i] = friendIds;
    }
  }

  Future<List<String>> _fetchRandomFriends() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .get();
    List<String> allFriendIds =
    friendsSnapshot.docs.map((doc) => doc['friendId'] as String).toList();
    allFriendIds.shuffle();
    return allFriendIds.take(4).toList();
  }

  void _voteIndex(int pageIndex, String userId, String greeting) async {
    if (_voteCompleted[pageIndex] == true || !mounted) return;
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    if (!_optionsMap[pageIndex]!.contains(userId)) return;

    Timestamp timestamp = Timestamp.now();
    Map<String, dynamic> voteIndices = {};
    List<String> userOrder = _optionsMap[pageIndex]!;

    for (int i = 0; i < userOrder.length; i++) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userOrder[i])
          .get();
      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
        userSnapshot.data() as Map<String, dynamic>;
        voteIndices['vindex${i + 1}'] = userData['firstname'];
      }
    }

    String voteBackgroundHexString =
        _pageBackgroundColors[pageIndex]?.value.toRadixString(16) ?? '';
    if (voteBackgroundHexString.isNotEmpty) {
      voteBackgroundHexString = '0x$voteBackgroundHexString';
    }

    String? receiverToken = await _getUserFCMToken(userId);

    // UUID 패키지를 사용하여 무작위 ID 생성
    var uuid = Uuid();
    String voteId = uuid.v4();

    FirebaseFirestore.instance.collection('votes').doc(voteId).set({
      'voterID': currentUserId,
      'receiverID': userId,
      'greeting': greetingData[greeting],
      'timestamp': timestamp,
      'emoji': greeting,
      'voteid': voteId,
      'secretMode': _pageSecretMode[pageIndex], // 각 페이지의 시크릿 모드 상태 추가
      ...voteIndices,
      'votebackground': voteBackgroundHexString,
      'receiverToken': receiverToken,
    }).then((_) {
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'voteIndex': FieldValue.increment(1),
      });
      setState(() {
        _voteCompleted[pageIndex] = true;
        _selectedUserForVote[pageIndex] = userId;
        _completedVotesCount++;
        if (_pageSecretMode[pageIndex] == true) {
          _secretModeCount--; // 시크릿 모드 사용 시 카운트 감소
          // 시크릿 모드 배경색을 유지
          _pageSecretMode[pageIndex] = true;
        }
        if (_completedVotesCount % 10 == 0) {
          _updateUserPoints(10); // 10개의 투표가 완료되면 30포인트 지급
        }
      });
    });

    if (receiverToken != null) {
      try {
        await FCMController().sendMessage(
          userToken: receiverToken,
          title: '새로운 투표가 도착했습니다!',
          body: '새로운 투표가 도착했습니다. 지금 확인해보세요!',
        );
      } catch (e) {
        print('푸시 알림을 보내는 데 문제가 발생했습니다: $e');
      }
    }
  }

  Future<void> _updateUserPoints(int points) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    DocumentReference userRef =
    FirebaseFirestore.instance.collection('users').doc(currentUserId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception("사용자 문서가 존재하지 않습니다.");
      }

      int newPoints =
          (snapshot.data() as Map<String, dynamic>)['points'] + points;
      transaction.update(userRef, {'points': newPoints});
      setState(() {
        _earnedPoints += points; // 이번 투표로 얻은 포인트 수 업데이트
      });
    });

    // 포인트 획득 기록을 현재 사용자 문서 아래 points 하위 컬렉션에 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('points')
        .add({
      'pointsource': 'vote',
      'points': points,
      'pointtimestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _reloadOptionsForCurrentPage(int pageIndex) async {
    if (_shuffleCount == 0 || !mounted) return;
    List<String> newOptions = await _fetchRandomFriends();
    setState(() {
      _optionsMap[pageIndex] = newOptions;
      _shuffleCount--;
    });
  }

  void _startAnimation() {
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          _position = _isGoingUp ? -5.0 : 5.0;
          _isGoingUp = !_isGoingUp;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Color _getPastelColor() {
    Random random = Random();
    int minChannelValue = 150; // 최소 채널 값 설정
    int maxChannelValue = 255; // 최대 채널 값 설정

    int red = minChannelValue + random.nextInt(maxChannelValue - minChannelValue + 1);
    int green = minChannelValue + random.nextInt(maxChannelValue - minChannelValue + 1);
    int blue = minChannelValue + random.nextInt(maxChannelValue - minChannelValue + 1);

    return Color.fromRGBO(red, green, blue, 1.0); // 밝은 파스텔 색상을 위해 알파 값 증가
  }

  Future<String?> _getUserFCMToken(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
      userSnapshot.data() as Map<String, dynamic>;
      return userData['fcmToken'] as String?;
    }
    return null;
  }

  void _subscribeToUnreadMessageCount() {
    MessageService().unreadMessageCountStream.listen((count) {
      setState(() {
        _unreadMessageCount = count;
      });
    });
    MessageService().subscribeToChatRooms();
  }

  void _handleScroll() {
    double currentOffset = _pageController.offset;
    int newPageIndex = _pageController.page!.round();

    if (newPageIndex != _currentPageIndex) {
      // Page has changed
      if (newPageIndex < _currentPageIndex) {
        // Scrolling up
        setState(() {
          _showButtons = true;
        });
      } else {
        // Scrolling down
        setState(() {
          _showButtons = false;
        });
      }
      _currentPageIndex = newPageIndex;
    }

    _lastOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    // 초기화가 완료될 때까지 로딩 화면 표시
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Container(color: Colors.white,),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _friendCount >= 4
          ? PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _maxPageCount, // Include PostvotePage
        itemBuilder: (context, index) {
          if (index == 0) {
            return const More4PrevotePage();
          } else if (index == _maxPageCount - 1) {
            // 마지막 페이지를 위해 -1
            return PostvotePage(
              remainingQuestions:
              _maxPageCount - 2 - _completedVotesCount,
              earnedPoints: _earnedPoints,
            );
          } else {
            return _buildHorizontalPageView(index);
          }
        },
      )
          : const Less4PrevotePage(),
    );
  }

  Widget _buildHorizontalPageView(int pageIndex) {
    PageController horizontalPageController = PageController(initialPage: 1);

    return PageView(
      controller: horizontalPageController,
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        Container(
          color: Colors.blueGrey[200],
          child: RankingPage(),
        ),
        Container(
          color: _pageSecretMode[pageIndex] ?? false
              ? Colors.grey[700] // 시크릿 모드일 때 배경 회색
              : (_voteCompleted[pageIndex] ?? false
              ? (_pageBackgroundColors[pageIndex] ?? _getPastelColor())
              : Colors.grey[200]),
          child: _buildVoteContent(pageIndex, horizontalPageController),
        ),
        Container(
          color: Colors.blueGrey[200],
          child: DmRoomPage(),
        ),
      ],
    );
  }

  Widget _buildVoteContent(
      int pageIndex, PageController horizontalPageController) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(10.h, 64, 10.h, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: IconButton(
                    icon: Icon(CupertinoIcons.chart_bar_alt_fill, size: 24.sp),
                    onPressed: () {
                      horizontalPageController.animateToPage(2,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  ),
                ),
              ),
              Text(
                '${pageIndex}/10',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                child: AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.mail_solid, size: 24.sp),
                        onPressed: () {
                          horizontalPageController.animateToPage(2,
                              duration: Duration(milliseconds: 300),
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
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 20.h, 0, 10.h),
          child: Text(
            greetingData.containsKey(_greetings[pageIndex])
                ? greetingData[_greetings[pageIndex]]!
                : '',
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 20.h, 0, 20.h),
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double emojiSize = constraints.maxWidth * 0.5;
              return Center(
                child: AnimatedEmoji(
                  AnimatedEmojis.fromName(_greetings[pageIndex]),
                  size: emojiSize,
                ),
              );
            },
          ),
        ),
        SingleChildScrollView(
          child: Container(
            height: 265,
            margin: EdgeInsets.fromLTRB(35.h, 0, 35.h, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: _buildFriendGrid(pageIndex),
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 10.h, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Spacer(),
              if (!_voteCompleted[pageIndex]!)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15.w),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 10.h),
                      backgroundColor: Colors.white,
                    ),
                    icon: Icon(
                      color: Colors.black,
                      _pageSecretMode[pageIndex] ?? false
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                      size: 20.sp,
                    ),
                    label: Text(
                      '${_secretModeCount < 0 ? 0 : _secretModeCount}/1',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: _pageSecretMode[pageIndex] == true ||
                        (_pageSecretMode[pageIndex] == false &&
                            _secretModeCount > 0)
                        ? () {
                      setState(() {
                        if (_pageSecretMode[pageIndex]!) {
                          _secretModeCount++;
                        } else {
                          if (_secretModeCount > 0) {
                            _secretModeCount--;
                          }
                        }
                        _pageSecretMode[pageIndex] =
                        !_pageSecretMode[pageIndex]!;
                      });
                    }
                        : null,
                  ),
                ),
              if (!_voteCompleted[pageIndex]!)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15.w),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 10.h),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: _shuffleCount > 0
                        ? () => _reloadOptionsForCurrentPage(pageIndex)
                        : null,
                    icon: Icon(CupertinoIcons.arrow_2_circlepath,
                        size: 20.sp, color: Colors.black),
                    label: Text(
                      '${_shuffleCount}/3',
                      style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              if (!_voteCompleted[pageIndex]!)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15.w),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 10.h),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(Icons.swipe_up_rounded,
                        size: 20.sp, color: Colors.black),
                    label: Text(
                      '스킵',
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              _buildVoteCompletionIndicator(pageIndex),
              Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendGrid(int pageIndex) {
    return GridView.builder(
      padding: EdgeInsets.all(10.w),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 1.2 / 1.0,
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: _optionsMap[pageIndex]?.length ?? 0,
      itemBuilder: (context, i) {
        String userId = _optionsMap[pageIndex]![i];
        return _buildFriendOption(pageIndex, userId);
      },
    );
  }

  Widget _buildFriendOption(int pageIndex, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String userName = userData['firstname'];
        String major = userData['major'];
        String gender = userData['gender'];
        String imagePath =
        gender == '남자' ? 'assets/men.png' : 'assets/female.png'; // 이미지 경로 설정
        bool isSelected = _selectedUserForVote[pageIndex] == userId;
        return Container(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _voteCompleted[pageIndex]!
                  ? (isSelected
                  ? (_pageSecretMode[pageIndex] ?? false
                  ? _pageBackgroundColors[pageIndex]
                  : _pageBackgroundColors[pageIndex])
                  : Colors.grey)
                  : _pageBackgroundColors[pageIndex],
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            onPressed: _voteCompleted[pageIndex]! && !isSelected
                ? null
                : () {
              if (!_voteCompleted[pageIndex]!) {
                _voteIndex(pageIndex, userId, _greetings[pageIndex]);
                setState(() {
                  _voteCompleted[pageIndex] = true;
                  _selectedUserForVote[pageIndex] = userId;
                  if (_pageSecretMode[pageIndex] == true) {
                    _secretModeCount--;
                    // 시크릿 모드 비활성화 하지 않음
                  }
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 30.w,
                  height: 30.h,
                ),
                SizedBox(height: 5.h),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 17.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  major,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoteCompletionIndicator(int pageIndex) {
    return _voteCompleted[pageIndex] ?? false
        ? Container(
      margin: EdgeInsets.fromLTRB(0, 10.h, 0, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0.0, _position, 0.0),
        child: Text(
          "위로 밀어서 다음 카드 보기",
          style: TextStyle(fontSize: 20.sp, color: Colors.white),
        ),
      ),
    )
        : Container();
  }
}