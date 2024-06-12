import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendListPage extends StatelessWidget {
  final String currentUserId;

  FriendListPage({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '내가 추가한 친구',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
        ),
        backgroundColor: Colors.white,
      ),
      body: FriendList(currentUserId: currentUserId),
    );
  }
}

class FriendList extends StatefulWidget {
  final String currentUserId;

  FriendList({required this.currentUserId});

  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  Map<String, ValueNotifier<bool>> deletedFriends = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('friends')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('친구 목록을 가져오는 중 오류가 발생했습니다.'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Container(color: Colors.white,));
        }

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Center(
            child: Text(
              '아직 친구가 없습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final friendDocument = documents[index];
            final String friendId = friendDocument.id;
            final Map<String, dynamic> friendData = friendDocument.data() as Map<String, dynamic>;

            if (!deletedFriends.containsKey(friendId)) {
              deletedFriends[friendId] = ValueNotifier<bool>(false);
            }

            return FriendTile(
              currentUserId: widget.currentUserId,
              friendId: friendId,
              friendData: friendData,
              isDeletedNotifier: deletedFriends[friendId]!,
            );
          },
        );
      },
    );
  }
}

class FriendTile extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final Map<String, dynamic> friendData;
  final ValueNotifier<bool> isDeletedNotifier;

  FriendTile({
    required this.currentUserId,
    required this.friendId,
    required this.friendData,
    required this.isDeletedNotifier,
  });

  @override
  _FriendTileState createState() => _FriendTileState();
}

class _FriendTileState extends State<FriendTile> {
  Future<void> _deleteFriend() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('friends')
          .doc(widget.friendId)
          .delete();
      widget.isDeletedNotifier.value = true;
    } catch (error) {
      print('친구 삭제 오류: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('친구 삭제 중 오류가 발생했습니다.'),
        duration: Duration(seconds: 2),
      ));
    }
  }


  void _showDeleteBottomSheet(BuildContext context) {
    final String firstName = widget.friendData['firstname'] ?? '';
    final String lastName = widget.friendData['lastname'] ?? '';
    final String name = '$firstName $lastName';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20,20,20,0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '친구 삭제하기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text('정말로 $name님을 삭제하시겠습니까?', style: TextStyle(fontSize: 17)),
              SizedBox(height: 20),
              Container(
                height: 80.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('취소', style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteFriend();
                      },
                      child: Text('삭제', style: TextStyle(color: Colors.white,)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = widget.friendData['firstname'] ?? '';
    final String lastName = widget.friendData['lastname'] ?? '';
    final String name = '$firstName $lastName';
    final String major = widget.friendData['major'] ?? '';
    final String gender = widget.friendData['gender'] ?? '';

    final String imagePath = gender == '남자' ? 'assets/men.png' : 'assets/female.png';

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isDeletedNotifier,
      builder: (context, isDeleted, child) {
        return Container(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(imagePath),
              radius: 30,
            ),
            title: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text(major, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            trailing: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: EdgeInsets.all(3),
                width: 100,
                height: 70,
                color: Colors.grey[100],
                child: TextButton.icon(
                  onPressed: () => _showDeleteBottomSheet(context),
                  icon: Icon(CupertinoIcons.person_crop_circle_badge_checkmark, color: Colors.black, size: 20),
                  label: Text(
                    '친구',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}