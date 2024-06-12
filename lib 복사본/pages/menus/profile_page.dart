import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../premium/off_premium_page.dart';
import '../../premium/on_premium_page.dart';
import '../../profile/edit_hint_page.dart';
import '../../profile/friend_list_page.dart';
import '../../profile/my_point_page.dart';
import '../../profile/setting/setting_page.dart';
import '../../profile/user_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  TextEditingController hint1Controller = TextEditingController();
  TextEditingController hint2Controller = TextEditingController();
  TextEditingController hint3Controller = TextEditingController();
  List<String> friendList = [];
  List<String> sameMajorUsersList = [];
  String? currentUserMajor;
  int friendCount = 0;
  int addedMeCount = 0;
  int currentPoints = 0; // Store the current points
  bool isLoadingPoints = true;
  bool isPremium = false; // 프리미엄 상태를 저장할 변수 추가
  StreamSubscription<DocumentSnapshot>? _premiumSubscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _subscribeToPremiumStatus(); // 프리미엄 상태를 구독하여 변경 사항 추적
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    hint1Controller.dispose();
    hint2Controller.dispose();
    hint3Controller.dispose();
    _premiumSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    // Future.wait를 사용하여 모든 비동기 작업을 병렬로 실행
    await Future.wait([
      _loadHints(),
      _loadCurrentUserMajor(),
      _loadFriendList(),
      _countAddedMeFriends(),
      _loadSameMajorUsers(),
      _fetchCurrentPoints(), // Fetch points on initialization
    ]);
  }

  Future<void> _loadCurrentUserMajor() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(currentUser!.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>?;
      if (userData != null) {
        setState(() {
          currentUserMajor = userData['major'] as String?;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
        return userDoc.data() as Map<String, dynamic>?;
      }
    } catch (error) {
      print("사용자 정보 가져오기 실패: $error");
    }
    return null;
  }

  Future<void> _loadHints() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(currentUser!.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>?;
      if (userData != null) {
        setState(() {
          hint1Controller.text = userData['userhint1'] ?? '';
          hint2Controller.text = userData['userhint2'] ?? '';
          hint3Controller.text = userData['userhint3'] ?? '';
        });
      }
    }
  }

  Future<void> _loadFriendList() async {
    if (currentUser != null) {
      QuerySnapshot friendSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .get();
      setState(() {
        friendList = friendSnapshot.docs.map((doc) => doc.id as String).toList();
        friendCount = friendList.length;
      });
    }
  }

  Future<void> _countAddedMeFriends() async {
    try {
      if (currentUser != null) {
        final QuerySnapshot usersSnapshot =
        await _firestore.collection('users').get();
        int count = 0;
        for (final userDoc in usersSnapshot.docs) {
          final friendSnapshot = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('friends')
              .where('friendId', isEqualTo: currentUser!.uid)
              .get();
          if (friendSnapshot.size > 0) {
            count++;
          }
        }
        setState(() {
          addedMeCount = count;
        });
      }
    } catch (error) {
      print('나를 추가한 친구 수 조회 중 오류 발생: $error');
    }
  }

  Future<void> _loadSameMajorUsers() async {
    if (currentUser != null) {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      setState(() {
        sameMajorUsersList = usersSnapshot.docs
            .where((doc) =>
        doc['major'] == currentUserMajor &&
            doc.id != currentUser!.uid &&
            !friendList.contains(doc.id))
            .map((doc) => doc.id as String)
            .toList();
      });
    }
  }

  Future<void> _addOrRemoveFriend(String friendId) async {
    if (currentUser != null) {
      setState(() {
        if (friendList.contains(friendId)) {
          friendList.remove(friendId);
        } else {
          friendList.add(friendId);
        }
      });

      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      final friendRef = userRef.collection('friends').doc(friendId);
      final friendDoc = await friendRef.get();

      if (friendDoc.exists) {
        // 친구가 이미 추가된 경우 삭제
        await friendRef.delete();
      } else {
        // 친구가 추가되지 않은 경우 추가
        final friendData =
        (await _firestore.collection('users').doc(friendId).get()).data();
        if (friendData != null) {
          await friendRef.set({
            'friendId': friendId,
            'firstname': friendData['firstname'] ?? '',
            'major': friendData['major'] ?? '',
            'department': friendData['department'] ?? '',
            'addedAt': DateTime.now(),
          });
        }
      }
    }
  }

  void _navigateToEditHintPage(BuildContext context) async {
    final updatedHints = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: EditHintPage(
              hint1: hint1Controller.text,
              hint2: hint2Controller.text,
              hint3: hint3Controller.text,
            ),
          ),
        );
      },
    );

    if (updatedHints != null) {
      setState(() {
        hint1Controller.text = updatedHints['hint1'] ?? '';
        hint2Controller.text = updatedHints['hint2'] ?? '';
        hint3Controller.text = updatedHints['hint3'] ?? '';
      });
    }
  }

  Future<void> _fetchCurrentPoints() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    DocumentSnapshot userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
      userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        currentPoints = userData['points'] ?? 0;
        isLoadingPoints = false; // Update loading state
      });
    }
  }

  void _navigateToSubscriptionPage(BuildContext context) async {
    if (currentUser != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(currentUser!.uid).get();
      var userData = userDoc.data();
      if (userData is Map<String, dynamic> && userData['premium'] == 'on') {
        showModalBottomSheet<dynamic>(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext context) {
            return Container(child: OnPremiumPage());
          },
        );
      } else {
        // Show OffPremiumPage in a BottomSheet
        showModalBottomSheet<dynamic>(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext context) {
            return OffPremiumPage();
          },
        );
      }
    }
  }

  void _navigateToPage(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    _fetchData();
  }

  void _subscribeToPremiumStatus() {
    if (currentUser != null) {
      _premiumSubscription = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .snapshots()
          .listen((snapshot) {
        var userData = snapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            isPremium = userData['premium'] == 'on';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _usersStream =
    _firestore.collection('users').snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '프로필',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Container(
                child: OutlinedButton(
                  onPressed: () {
                    _navigateToSubscriptionPage(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isPremium ? Colors.transparent : Colors.blue, width: 2.0), // 프리미엄 상태에 따라 테두리 색상 변경
                    backgroundColor: isPremium ? Colors.blue : Colors.transparent, // 프리미엄 상태에 따라 배경 색상 변경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0), // 모서리 둥글게 설정
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Flirt Premium',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isPremium ? Colors.white : Colors.blue, // 프리미엄 상태에 따라 텍스트 색상 변경
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _navigateToPage(context, SettingPage());
                },
                icon: Icon(
                  Icons.settings,
                  size: 35,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 50,
                        backgroundImage: AssetImage('assets/men.png'),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: getCurrentUserInfo(),
                        builder: (BuildContext context,
                            AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox.shrink(); // 로딩 중에는 아무것도 표시하지 않음
                          } else {
                            final userInfo = snapshot.data;
                            final major = userInfo?['major'] ?? '';
                            final department = userInfo?['department'] ?? '';
                            return Text(
                              '$department / $major',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: getCurrentUserInfo(),
                        builder: (BuildContext context,
                            AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox.shrink(); // 로딩 중에는 아무것도 표시하지 않음
                          } else {
                            final firstName =
                                snapshot.data!['firstname'] ?? '이름 없음';
                            return Text(
                              '$firstName',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(30, 15, 30, 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _navigateToEditHintPage(context);
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "#${hint1Controller.text} #${hint2Controller.text} \n#${hint3Controller.text}",
                                    style: TextStyle(fontSize: 20, color: Colors.black),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                    "나만의 힌트",
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: isLoadingPoints
                                ? Container(color: Colors.white,) // Show loading indicator while fetching points
                                : TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyPointPage(),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/juicy-gold-coin.png',
                                        height: 30,
                                        width: 30,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        '$currentPoints', // Use current points from state
                                        style: TextStyle(
                                          fontSize: 23,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '현재 포인트',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _navigateToPage(context, FriendListPage(currentUserId: currentUser!.uid));
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "$friendCount",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 23, color: Colors.black),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                    "내가 추가한 친구",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                        "비밀이에요!!",
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      content: Text(
                                        "다른 사람들에게도 비밀입니다.",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text(
                                            "확인",
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "$addedMeCount",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 23, color: Colors.black),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                    "나를 추가한 친구",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        height: 10,
                        indent: 0,
                        endIndent: 0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.groups),
                              const SizedBox(width: 8),
                              Text("친구 추가하기",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              _navigateToPage(context, UserListPage());
                            },
                            style: ButtonStyle(
                              backgroundColor:
                              MaterialStateProperty.all<Color>(
                                  Colors.transparent),
                              elevation: MaterialStateProperty.all<double>(0),
                              foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                  EdgeInsets.all(0)),
                              overlayColor:
                              MaterialStateProperty.all<Color>(
                                  Colors.transparent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '전체보기 ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300),
                                ),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: sameMajorUsersList.length,
                        itemBuilder: (context, index) {
                          final userId = sameMajorUsersList[index];
                          final isFriend = friendList.contains(userId);

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('users').doc(userId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox.shrink(); // 로딩 중에는 아무것도 표시하지 않음
                              }

                              final userDoc = snapshot.data;
                              final name = userDoc!['firstname'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name, style: TextStyle(fontSize: 20)),
                                    Container(
                                      padding: EdgeInsets.all(3),
                                      width: 130,
                                      height: 40, // 높이 수정
                                      decoration: BoxDecoration(
                                        color: isFriend
                                            ? Colors.blue
                                            : Colors.grey[100],
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            _addOrRemoveFriend(userId);
                                          },
                                          icon: Icon(
                                            isFriend
                                                ? Icons.check
                                                : Icons.person_add,
                                            color: isFriend
                                                ? Colors.white
                                                : Colors.black,
                                            size: 18,
                                          ),
                                          label: Text(
                                            isFriend ? '추가됨' : '친구 추가',
                                            style: TextStyle(
                                              color: isFriend
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 16,
                                              fontWeight: isFriend
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                          style: ButtonStyle(
                                            alignment: Alignment.center, // 중앙 정렬
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}