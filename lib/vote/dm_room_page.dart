import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:logintest/chat/chat_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../chat/chat_service.dart';
import '../model/message_service.dart';

class DmRoomPage extends StatefulWidget {
  const DmRoomPage({Key? key}) : super(key: key);

  @override
  _DmRoomPageState createState() => _DmRoomPageState();
}

class _DmRoomPageState extends State<DmRoomPage> with AutomaticKeepAliveClientMixin<DmRoomPage> {
  Stream<QuerySnapshot>? _chatRoomsStream;
  late String _currentUserId;
  Map<String, int> _unreadMessagesCount = {};
  Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  int _unreadMessageCount = 0; // 추가

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    MessageService().unreadMessageCountStream.listen((count) {
      setState(() {
        _unreadMessageCount = count;
      });
    });
    MessageService().subscribeToChatRooms();
  }

  @override
  void dispose() {
    super.dispose();
    _cancelAllSubscriptions();
    MessageService().dispose(); // 추가
  }

  void _getCurrentUserId() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _currentUserId = userId;
        _loadChatRooms();
      });
    }
  }

  void _loadChatRooms() {
    _chatRoomsStream = ChatService().getChatRooms(_currentUserId);
    _chatRoomsStream?.listen((snapshot) {
      for (var doc in snapshot.docs) {
        _subscribeToUnreadMessages(doc.id);
      }
    });
  }

  void _subscribeToUnreadMessages(String chatRoomId) {
    if (_messageSubscriptions.containsKey(chatRoomId)) {
      _messageSubscriptions[chatRoomId]?.cancel();
    }

    var subscription = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverID', isEqualTo: _currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadMessagesCount[chatRoomId] = snapshot.docs.length;
      });
    });

    _messageSubscriptions[chatRoomId] = subscription;
  }

  void _cancelAllSubscriptions() {
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
  }

  void _confirmDeleteChatRoom(String chatRoomId) {
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
          content: Text('정말 이 채팅방을 삭제하시겠습니까?',style: TextStyle(
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
                _deleteChatRoom(chatRoomId);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteChatRoom(String chatRoomId) {
    FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).delete();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Initialize ScreenUtil
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('채팅 목록', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700)),
        surfaceTintColor: Colors.transparent,
      ),
      body: _chatRoomsStream == null
          ? Center(child: Container(color: Colors.white,))
          : StreamBuilder<QuerySnapshot>(
        stream: _chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Container(color: Colors.white,));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('아직 받은 카드가 없어요.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatRoom = snapshot.data!.docs[index];
              var users = List<String>.from(chatRoom['users']);
              users.remove(_currentUserId);
              String otherUserId = users.first;
              String voteId = chatRoom.id; // 채팅방의 voteId 사용

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(title: Text('Loading...'));
                  }
                  String otherUserEmail = userSnapshot.data!['email'];
                  String major = userSnapshot.data!['major'] ?? 'Unknown Major';
                  String hint1 = userSnapshot.data!['userhint1'] ?? 'No Hint';
                  String hint2 = userSnapshot.data!['userhint2'] ?? 'No Hint';
                  String hint3 = userSnapshot.data!['userhint3'] ?? 'No Hint';
                  String gender = userSnapshot.data!['gender'] ?? 'Unknown';

                  String lastMessage = chatRoom['lastMessage'];

                  String profileImage = gender == '남자' ? 'assets/men.png' : 'assets/female.png';

                  int unreadCount = _unreadMessagesCount[voteId] ?? 0;

                  return Slidable(
                    key: Key(voteId),
                    endActionPane: ActionPane(
                      extentRatio: 0.2,
                      dragDismissible: true,
                      motion: const StretchMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) => _confirmDeleteChatRoom(voteId),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '삭제',
                          padding: EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ],
                    ),
                    child: Container(
                      child: GestureDetector(
                        onHorizontalDragStart: (_) {},
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(profileImage),
                            radius: 30.r,
                          ),
                          title: Text(
                            major,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                          ),
                          subtitle: Text(
                            lastMessage,
                            style: TextStyle(
                              color: unreadCount > 0 ? Colors.black : Colors.grey,  // 읽음 여부에 따른 색상 변경
                              fontSize: 14.sp,
                            ),
                          ),
                          trailing: unreadCount > 0
                              ? CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.blue,
                            child: Text(
                              '$unreadCount',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                              : null,  // 읽음 상태에 따른 파란색 점
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('votes').doc(voteId).get(),
                                  builder: (context, voteSnapshot) {
                                    if (!voteSnapshot.hasData) {
                                      return Container(color: Colors.white,); // 혹은 적절한 로딩 위젯
                                    }
                                    String greeting = voteSnapshot.data!['greeting'] ?? '';

                                    return ChatPage(
                                      voterId: otherUserId,
                                      receiverEmail: otherUserEmail,
                                      hint1: hint1,
                                      hint2: hint2,
                                      hint3: hint3,
                                      greeting: greeting,
                                      voteId: voteId,
                                    );
                                  },
                                ),
                              ),
                            ).then((_) {
                              // 채팅방 열림 후 읽음 상태 업데이트
                              FirebaseFirestore.instance.collection('chat_rooms').doc(voteId).update({'isRead': true});
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}