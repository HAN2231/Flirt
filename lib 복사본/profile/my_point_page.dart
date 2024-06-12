import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart'; // 날짜 형식 포맷을 위해 추가

class MyPointPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My 포인트',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  '포인트 내역',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text(
                        '',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    }

                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final totalPoints = userData['points'] ?? 0;

                    return Row(
                      children: [
                        Text(
                          '전체 포인트 : ',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$totalPoints',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                        Image.asset(
                          'assets/juicy-gold-coin.png',
                          height: 20,
                          width: 20,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('points')
                  .orderBy('pointtimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final pointsDocs = snapshot.data!.docs;

                if (pointsDocs.isEmpty) {
                  // points 컬렉션이 없는 경우 생성
                  _initializePointsCollection(user?.uid);
                }

                return ListView.builder(
                  itemCount: pointsDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        pointsDocs[index].data() as Map<String, dynamic>;
                    final points = data['points'];
                    final timestamp =
                        (data['pointtimestamp'] as Timestamp).toDate();
                    final pointSource = data['pointsource'] == 'vote'
                        ? '투표    '
                        : data['pointsource'] == 'polls'
                            ? '폴스    '
                            : data['pointsource'];

                    // 날짜를 "yyyy-MM-dd" 형식으로 포맷
                    final formattedDate =
                        DateFormat('yy.MM.dd').format(timestamp);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pointSource,
                                style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '$formattedDate',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '+ $points',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(width: 5),
                                  Image.asset(
                                    'assets/juicy-gold-coin.png',
                                    height: 20,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // points 컬렉션 초기화 함수
  Future<void> _initializePointsCollection(String? userId) async {
    if (userId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('points')
        .add({
      'pointsource': '회원가입',
      'points': 100,
      'pointtimestamp': FieldValue.serverTimestamp(),
    });
  }
}
