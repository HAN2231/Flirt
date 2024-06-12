import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('친구 추가', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.search, size: 35),
            onPressed: () {
              showSearch(context: context, delegate: UserSearchDelegate());
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: UserList(),
          ),
        ],
      ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return UserList(searchQuery: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return UserList(searchQuery: query);
  }
}

class UserList extends StatefulWidget {
  final String? searchQuery;

  UserList({Key? key, this.searchQuery}) : super(key: key);

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  Set<String> friendIds = {};
  String? currentUserMajor;
  Map<String, ValueNotifier<bool>> addedFriends = {};

  @override
  void initState() {
    super.initState();
    _loadFriendList();
    _loadCurrentUserMajor();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('데이터를 불러오는 중 오류가 발생했습니다.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: Colors.white);
        }

        final users = snapshot.data!.docs;
        final Map<String, List<DocumentSnapshot>> usersByMajor = {};

        for (var user in users) {
          final major = user['major'] ?? '기타';
          if (!usersByMajor.containsKey(major)) {
            usersByMajor[major] = [];
          }
          if (!friendIds.contains(user.id) &&
              user.id != FirebaseAuth.instance.currentUser?.uid) {
            usersByMajor[major]!.add(user);
          }
        }

        List<String> sortedMajors = usersByMajor.keys.toList();
        sortedMajors.sort((a, b) => a.compareTo(b));

        if (currentUserMajor != null &&
            usersByMajor.containsKey(currentUserMajor)) {
          sortedMajors.remove(currentUserMajor);
          sortedMajors.insert(0, currentUserMajor!);
        }

        return ListView.builder(
          itemCount: sortedMajors.length,
          itemBuilder: (BuildContext context, int index) {
            final major = sortedMajors[index];
            final usersInMajor = usersByMajor[major]!;

            if (usersInMajor.isEmpty) {
              return SizedBox();
            }

            final filteredUsers = widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                ? usersInMajor.where((user) {
              final firstName = user['firstname']?.toString() ?? '';
              final fullName = '$firstName';
              final major = user['major']?.toString() ?? '';
              return fullName.toLowerCase().contains(widget.searchQuery!.toLowerCase()) ||
                  major.toLowerCase().contains(widget.searchQuery!.toLowerCase());
            }).toList()
                : usersInMajor;

            if (filteredUsers.isEmpty) {
              return SizedBox();
            }

            return Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index != 0) Divider(thickness: 1, color: Colors.grey[300], indent: 15, endIndent: 15,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      major,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredUsers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final user = filteredUsers[index];
                      final firstName = user['firstname'] ?? '';
                      final fullName = '$firstName';
                      final userId = user.id;

                      if (!addedFriends.containsKey(userId)) {
                        addedFriends[userId] = ValueNotifier<bool>(false);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                            child: ListTile(
                              title: Text(
                                fullName,
                                style: TextStyle(fontSize: 20),
                              ),
                              trailing: ValueListenableBuilder<bool>(
                                valueListenable: addedFriends[userId]!,
                                builder: (context, isAdded, child) {
                                  return Container(
                                    width: 130,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isAdded ? Colors.blue : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: isAdded
                                          ? TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          alignment: Alignment.center,
                                        ),
                                        onPressed: () {
                                          addedFriends[userId]!.value = false;
                                          _removeFriend(userId);
                                        },
                                        icon: Icon(Icons.check, size: 18, color: Colors.white),
                                        label: Text(
                                          '추가됨',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                          : TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          alignment: Alignment.center,
                                        ),
                                        onPressed: () {
                                          addedFriends[userId]!.value = true;
                                          _addFriend(userId);
                                        },
                                        icon: Icon(Icons.person_add,
                                            size: 18, color: Colors.black),
                                        label: Text(
                                          '친구 추가',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadCurrentUserMajor() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      setState(() {
        currentUserMajor = userDoc['major'];
      });
    }
  }

  Future<void> _loadFriendList() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final friendSnapshot = await userRef.collection('friends').get();
      setState(() {
        friendIds = friendSnapshot.docs.map((doc) => doc.id).toSet();
      });
    }
  }

  Future<void> _addFriend(String friendId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final friendRef = FirebaseFirestore.instance.collection('users').doc(friendId);
      final friendDoc = await friendRef.get();

      if (friendDoc.exists) {
        final friendData = friendDoc.data() as Map<String, dynamic>; // 친구의 데이터를 가져옵니다.

        // Firestore에 친구 정보를 저장합니다. 이 때, department, firstname, major 정보도 함께 저장합니다.
        await userRef.collection('friends').doc(friendDoc.id).set({
          'friendId': friendDoc.id,
          'addedAt': DateTime.now(),
          'department': friendData['department'], // 친구의 부서
          'firstname': friendData['firstname'], // 친구의 이름
          'major': friendData['major'], // 친구의 전공
          'gender': friendData['gender'],
        });
      }
    }
  }

  Future<void> _removeFriend(String friendId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      await userRef.collection('friends').doc(friendId).delete();
    }
  }
}