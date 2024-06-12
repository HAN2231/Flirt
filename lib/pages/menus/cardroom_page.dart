import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../vote/voteinfo/vote_info_page.dart';

class CardRoomPage extends StatefulWidget {
  const CardRoomPage({Key? key});

  @override
  _CardRoomPageState createState() => _CardRoomPageState();
}

class _CardRoomPageState extends State<CardRoomPage> with AutomaticKeepAliveClientMixin<CardRoomPage> {
  late Stream<QuerySnapshot> _votesStream;
  late String _currentUserId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadVotes();
  }

  void _getCurrentUserId() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _loadVotes() {
    _votesStream = FirebaseFirestore.instance
        .collection('votes')
        .where('receiverID', isEqualTo: _currentUserId)
        .snapshots();
  }

  void _confirmDeleteVote(String voteId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('삭제 확인',style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
              color: Colors.black
          ),),
          content: Text('정말 이 카드를 삭제하시겠습니까?',style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black,fontWeight: FontWeight.w500),),
          actions: [
            TextButton(
              child: Text('취소',style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey
              ),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('삭제',style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.red),),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVote(voteId);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteVote(String voteId) {
    FirebaseFirestore.instance.collection('votes').doc(voteId).delete();
  }

  void _navigateToVoteInfoPage(BuildContext context, String voteId, String voterID, String greeting, String emoji, String vindex1, String vindex2, String vindex3, String vindex4, String votebackground) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VoteInfoPage(
          voteId: voteId,
          voterId: voterID,
          greeting: greeting,
          emoji: emoji,
          vindex1: vindex1,
          vindex2: vindex2,
          vindex3: vindex3,
          vindex4: vindex4,
          votebackground: votebackground,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text('받은 카드', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 23.sp)),
        centerTitle: false,
        /*actions: [
          Container(
            padding: EdgeInsets.fromLTRB(0, 0, 10.sp, 0),
            child: IconButton(
              iconSize: 32,
              icon: Icon(Icons.filter_list),
              color: Colors.black,
              onPressed: () {
                // 아이콘 버튼을 눌렀을 때 실행할 코드를 여기에 작성합니다.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('남녀 정렬!')),
                );
              },
            ),
          ),
        ],*/
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _votesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5, // Number of skeleton items to show
              itemBuilder: (context, index) {
                return Container(
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      padding: EdgeInsets.all(7),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[300],
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 15,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 7),
                                Container(
                                  height: 15,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('아직 받은 카드가 없어요.'),
            );
          }

          // 최신순으로 정렬
          var votes = snapshot.data!.docs;
          votes.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

          return ListView.builder(
            itemCount: votes.length + 1,
            itemBuilder: (context, index) {
              if (index == votes.length) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      '전부 확인 했어요!',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                );
              } else {
                var vote = votes[index];
                String voteId = vote.id;
                String voterID = vote['voterID'];
                String greeting = vote['greeting'];
                String emoji = vote['emoji'];
                String vindex1 = vote['vindex1'];
                String vindex2 = vote['vindex2'];
                String vindex3 = vote['vindex3'];
                String vindex4 = vote['vindex4'];
                String votebackground = vote['votebackground'];
                bool secretMode = vote['secretMode'] ?? false;

                var userRef = FirebaseFirestore.instance.collection('users').doc(voterID);

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: Slidable(
                    key: Key(voteId),
                    endActionPane: ActionPane(
                      extentRatio: 0.2,
                      dragDismissible: true ,
                      motion: StretchMotion(),
                      children: [
                        SlidableAction(
                          borderRadius: BorderRadius.circular(20),
                          onPressed: (context) => _confirmDeleteVote(voteId),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '삭제',
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          // 패딩을 조정하여 더 작은 공간 사용
                        ),
                      ],
                    ),
                    child: Card(
                      color: Color(0xF8F7F9FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () {
                          _navigateToVoteInfoPage(
                            context,
                            voteId,
                            voterID,
                            greeting,
                            emoji,
                            vindex1,
                            vindex2,
                            vindex3,
                            vindex4,
                            votebackground,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0xF8F7F9FF),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Color(0xF8F7F9FF),
                                child: emoji.isNotEmpty
                                    ? AnimatedEmoji(
                                  AnimatedEmojis.fromName(emoji),
                                  size: 42.0,
                                )
                                    : Icon(Icons.error, size: 30.0, color: Colors.red),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '  $greeting',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 7),
                                    secretMode
                                        ? Text(
                                      '  시크릿 모드 사용자에게 받았어요.',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                        : StreamBuilder<DocumentSnapshot>(
                                      stream: userRef.snapshots(),
                                      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        if (!snapshot.hasData || !snapshot.data!.exists) {
                                          return const SizedBox();
                                        }
                                        var userData = snapshot.data!;
                                        var voterHint1 = userData['userhint1'];
                                        var voterHint2 = userData['userhint2'];
                                        var voterHint3 = userData['userhint3'];
                                        var major = userData['major'];
                                        return Text(
                                          '  $major #$voterHint1, #$voterHint2, #$voterHint3',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}