import 'dart:ui';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'bottom_chat_page.dart';
import '../../chat/chat_page.dart';
import '../../chat/chat_service.dart';
import 'check_voter_page.dart';
import '../../premium/off_premium_page.dart';
import 'secret_vote_page.dart';

class VoteInfoPage extends StatelessWidget {
  final String voteId; // 추가된 voteId
  final String voterId;
  final String greeting;
  final String emoji;
  final String vindex1;
  final String vindex2;
  final String vindex3;
  final String vindex4;
  final String votebackground;

  const VoteInfoPage({
    Key? key,
    required this.voteId, // 추가된 voteId
    required this.voterId,
    required this.greeting,
    required this.emoji,
    required this.vindex1,
    required this.vindex2,
    required this.vindex3,
    required this.vindex4,
    required this.votebackground,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _getUserDataByFirstname(String firstname) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('firstname', isEqualTo: firstname)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Widget _buildFriendOption(String firstname, String currentUserFirstName, Color tileColor) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserDataByFirstname(firstname),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(20.r),
              ),
              width: 100.w,
              height: 100.h,
            ),
          );
        }
        final userData = snapshot.data!;
        final userName = userData['firstname'];
        final major = userData['major'] ?? '전공 없음';
        final gender = userData['gender'] ?? '성별 없음';
        final imagePath = gender == '남자' ? 'assets/men.png' : 'assets/female.png';

        final backgroundColor = userName == currentUserFirstName ? tileColor : Colors.grey[100];

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20.r),
          ),
          alignment: Alignment.center,
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
                style: TextStyle(fontSize: 17.sp, color: Colors.black),
              ),
              SizedBox(height: 4.h),
              Text(
                major,
                style: TextStyle(fontSize: 15.sp, color: Colors.grey[700]),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChatBottomSheet(BuildContext context, String receiverEmail, String hint1, String hint2, String hint3, String greeting, int currentPoints) {
    showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: ChatBottomPage(
            receiverEmail: receiverEmail,
            voterId: voterId,
            hint1: hint1,
            hint2: hint2,
            hint3: hint3,
            greeting: greeting,
            currentPoints: currentPoints,
            voteId: voteId,
          ),
        );
      },
    );
  }

  Future<void> _checkAndNavigateToChat(BuildContext context, String receiverEmail, String hint1, String hint2, String hint3, String greeting, int currentPoints) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ChatService _chatService = ChatService();
    if (currentUser != null) {
      // 채팅방 ID를 voteId로 설정
      String chatRoomID = voteId;

      bool chatRoomExists = await _chatService.isChatRoomExists(chatRoomID);

      if (chatRoomExists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              voteId: voteId, // 전달된 voteId 사용
              receiverEmail: receiverEmail,
              voterId: voterId,
              hint1: hint1,
              hint2: hint2,
              hint3: hint3,
              greeting: greeting,
            ),
          ),
        );
      } else {
        _showChatBottomSheet(context, receiverEmail, hint1, hint2, hint3, greeting, currentPoints);
      }
    }
  }

  void _navigateToSubscriptionPage(BuildContext context, bool secretMode) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      var userData = userDoc.data();
      if (userData is Map<String, dynamic> && userData['premium'] == 'on') {
        showModalBottomSheet<dynamic>(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                width: double.infinity,
                height: 420,
                child: secretMode ? SecretVotePage() : CheckVoterPage(voterId: voterId),
              ),
            );
          },
        );
      } else {
        showModalBottomSheet<dynamic>(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: OffPremiumPage(),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
        child: Center(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(color: Colors.white,
                );
              }
              if (snapshot.hasError) {
                return Text('오류: ${snapshot.error}', style: TextStyle(fontSize: 16.sp));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text('사용자 정보를 찾을 수 없습니다.', style: TextStyle(fontSize: 16.sp));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final currentUserFirstName = userData['firstname'];
              final receiverEmail = userData['email'];
              final currentPoints = userData['points'];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('votes')
                    .where('receiverID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, voteSnapshot) {
                  if (voteSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(color: Colors.white,
                    );
                  }
                  if (voteSnapshot.hasError) {
                    return Text('오류: ${voteSnapshot.error}', style: TextStyle(fontSize: 16.sp));
                  }
                  if (voteSnapshot.data == null || voteSnapshot.data!.docs.isEmpty) {
                    return Text('받은 투표가 없습니다.', style: TextStyle(fontSize: 16.sp));
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('votes').doc(voteId).get(),
                    builder: (context, voteDetailSnapshot) {
                      if (voteDetailSnapshot.connectionState == ConnectionState.waiting) {
                        return Container(color: Colors.white,
                        );
                      }
                      if (voteDetailSnapshot.hasError) {
                        return Text('오류: ${voteDetailSnapshot.error}', style: TextStyle(fontSize: 16.sp));
                      }
                      if (!voteDetailSnapshot.hasData || !voteDetailSnapshot.data!.exists) {
                        return Text('투표 정보를 찾을 수 없습니다.', style: TextStyle(fontSize: 16.sp));
                      }

                      final voteData = voteDetailSnapshot.data!.data() as Map<String, dynamic>;
                      final secretMode = voteData['secretMode'] ?? false;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(voterId).get(),
                        builder: (context, voterSnapshot) {
                          if (voterSnapshot.connectionState == ConnectionState.waiting) {
                            return Container(color: Colors.white,
                            );
                          }
                          if (voterSnapshot.hasError) {
                            return Text('오류: ${voterSnapshot.error}', style: TextStyle(fontSize: 16.sp));
                          }
                          if (!voterSnapshot.hasData || !voterSnapshot.data!.exists) {
                            return Text('투표자 정보를 찾을 수 없습니다.', style: TextStyle(fontSize: 16.sp));
                          }

                          final voterData = voterSnapshot.data!.data() as Map<String, dynamic>;
                          final hint1 = voterData['userhint1'] ?? '힌트 없음';
                          final hint2 = voterData['userhint2'] ?? '힌트 없음';
                          final hint3 = voterData['userhint3'] ?? '힌트 없음';
                          final major = voterData['major'] ?? '';

                          final voteBackgroundColor = Color(int.parse(votebackground));

                          return SingleChildScrollView(
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: voteBackgroundColor,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    padding: EdgeInsets.fromLTRB(20.w, 10.w, 20.w, 10.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 10.h),
                                        secretMode
                                            ? Text(
                                          '시크릿 모드 사용자에게 받았어요.',
                                          style: TextStyle(fontSize: 18.sp, color: Colors.black),
                                        )
                                            : Column(
                                          children: [
                                            Text(
                                              '$major',
                                              style: TextStyle(fontSize: 18.sp, color: Colors.black),
                                            ),
                                            Text(
                                              '#$hint1, #$hint2, #$hint3한테 투표를 받았어요.',
                                              style: TextStyle(fontSize: 14.sp, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 15.h),
                                        Center(
                                          child: Text(
                                            greeting,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 20.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20.h),
                                        SizedBox(
                                          width: double.infinity,
                                          child: AnimatedEmoji(
                                            AnimatedEmojis.fromName(emoji),
                                            size: 150.h,
                                          ),
                                        ),
                                        SizedBox(height: 20.h),
                                        Container(
                                          height: 210.h,
                                          padding: EdgeInsets.all(5.w),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20.r),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 5,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: GridView.builder(
                                            shrinkWrap: false,
                                            physics: NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 8.h,
                                              mainAxisSpacing: 8.h,
                                              childAspectRatio: 1.2 / 1.0,
                                            ),
                                            itemCount: 4,
                                            itemBuilder: (context, index) {
                                              String vindex;

                                              switch (index) {
                                                case 0:
                                                  vindex = vindex1;
                                                  break;
                                                case 1:
                                                  vindex = vindex2;
                                                  break;
                                                case 2:
                                                  vindex = vindex3;
                                                  break;
                                                case 3:
                                                  vindex = vindex4;
                                                  break;
                                                default:
                                                  vindex = '';
                                              }

                                              return _buildFriendOption(
                                                vindex,
                                                currentUserFirstName,
                                                voteBackgroundColor,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Container(
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _navigateToSubscriptionPage(context, secretMode);
                                          },
                                          icon: Icon(
                                            Icons.visibility,
                                            size: 20.sp,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            '누가 보냈는지 보기',
                                            style: TextStyle(fontSize: 18.sp, color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _checkAndNavigateToChat(context, receiverEmail, hint1, hint2, hint3, greeting, currentPoints);
                                          },
                                          icon: Icon(
                                            CupertinoIcons.chat_bubble_text_fill,
                                            size: 20.sp,
                                            color: Colors.blue,
                                          ),
                                          label: Text(
                                            '채팅',
                                            style: TextStyle(fontSize: 18.sp, color: Colors.blue),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[100],
                                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 15.h),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
