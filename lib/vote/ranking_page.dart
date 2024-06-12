import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../components/greeting_data.dart';

class RankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('랭킹',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('users').get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(
              child: Container(color: Colors.white,),
            );
          }

          // Create a map of user IDs to their first names, majors, and genders
          Map<String, String> userNames = {};
          Map<String, String> userMajors = {};
          Map<String, String> userGenders = {};
          userSnapshot.data!.docs.forEach((doc) {
            userNames[doc.id] = doc['firstname'];
            userMajors[doc.id] = doc['major'];
            userGenders[doc.id] = doc['gender'];
          });

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('votes')
                .orderBy('receiverID', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Container(color: Colors.white,),
                );
              }

              Map<String, Map<String, dynamic>> questionVotes = {};

              snapshot.data!.docs.forEach((doc) {
                String receiverID = doc['receiverID'];
                String greeting = doc['greeting'];
                String emoji = doc['emoji'];

                if (!questionVotes.containsKey(greeting)) {
                  questionVotes[greeting] = {
                    'votes': <String, int>{},
                    'emoji': emoji
                  };
                }
                questionVotes[greeting]?['votes'][receiverID] =
                    (questionVotes[greeting]?['votes'][receiverID] ?? 0) + 1;
              });

              List<String> greetings = questionVotes.keys.toList();
              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: greetings.length,
                itemBuilder: (context, index) {
                  String greeting = greetings[index];
                  Map<String, int> voteCountMap =
                  Map<String, int>.from(questionVotes[greeting]?['votes']);
                  String emoji = questionVotes[greeting]?['emoji'];
                  List<MapEntry<String, int>> sortedVotes =
                  voteCountMap.entries.toList();
                  sortedVotes.sort((a, b) => b.value.compareTo(a.value));

                  return Container(
                    height: MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            '${greetingData[greeting] ?? greeting}',
                            textAlign: TextAlign.center, // 추가된 속성
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: 30), // Add space between title and emoji
                        AnimatedEmoji(
                          AnimatedEmojis.fromName(emoji),
                          size: 180.sp,
                        ),
                        SizedBox(
                            height: 20.h), // Add space between emoji and bars
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildPodium(
                                  sortedVotes.length > 1
                                      ? sortedVotes[1].value
                                      : 0,
                                  sortedVotes.length > 1
                                      ? userNames[sortedVotes[1].key] ?? ''
                                      : '',
                                  sortedVotes.length > 1
                                      ? userMajors[sortedVotes[1].key] ?? ''
                                      : '',
                                  sortedVotes.length > 1
                                      ? userGenders[sortedVotes[1].key] ?? ''
                                      : '',
                                  sortedVotes.length > 1
                                      ? Color(0xffd8d8d8)
                                      : Colors.grey,
                                  1.8,
                                  1.4,
                                  sortedVotes.length > 1,
                                  2 // 2등
                              ),
                              _buildPodium(
                                  sortedVotes.isNotEmpty
                                      ? sortedVotes[0].value
                                      : 0,
                                  sortedVotes.isNotEmpty
                                      ? userNames[sortedVotes[0].key] ?? ''
                                      : '',
                                  sortedVotes.isNotEmpty
                                      ? userMajors[sortedVotes[0].key] ?? ''
                                      : '',
                                  sortedVotes.isNotEmpty
                                      ? userGenders[sortedVotes[0].key] ?? ''
                                      : '',
                                  sortedVotes.isNotEmpty
                                      ? Colors.amber
                                      : Colors.grey,
                                  2.3, // 높이
                                  1.8, // 너비
                                  sortedVotes.isNotEmpty,
                                  1 // 1등
                              ),
                              _buildPodium(
                                  sortedVotes.length > 2
                                      ? sortedVotes[2].value
                                      : 0,
                                  sortedVotes.length > 2
                                      ? userNames[sortedVotes[2].key] ?? ''
                                      : '',
                                  sortedVotes.length > 2
                                      ? userMajors[sortedVotes[2].key] ?? ''
                                      : '',
                                  sortedVotes.length > 2
                                      ? userGenders[sortedVotes[2].key] ?? ''
                                      : '',
                                  sortedVotes.length > 2
                                      ? Colors.orange
                                      : Colors.grey,
                                  1.5,
                                  1.4,
                                  sortedVotes.length > 2,
                                  3 // 3등
                              ),
                            ],
                          ),
                        ),
                        // Add space between bars and bottom of the page
                      ],
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

  Widget _buildPodium(
      int votes,
      String label,
      String major,
      String gender,
      Color color,
      double heightFactor,
      double widthFactor,
      bool hasVotes,
      int rank) {
    String genderImage =
    gender == '남자' ? 'assets/men.png' : 'assets/female.png';
    return Column(
      mainAxisAlignment: MainAxisAlignment.end, // Adjust vertical alignment
      children: [

        // if (rank == 1) // 1등일 때만 왕관 표시
        //   Icon(Icons.military_tech,color: Colors. amberAccent,size: 50.sp,),
        if (rank == 1) // 1등일 때만 왕관 표시
          Text('👑', style: TextStyle(fontSize: 30.sp)),
        Text(
          hasVotes ? '$votes 표' : '-',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp),
        ),
        SizedBox(height: 8), // Add space between votes and container
        Stack(
          children: [
            Container(
              height: 100 * heightFactor, // Adjust height by the factor
              width: 70 * widthFactor, // Adjust width by the factor
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10), // 모서리를 둥글게 설정
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(4, 4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                height: 100 * heightFactor - 20,
                width: 70 * widthFactor - 20,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      major,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11.sp,
                          color: Colors.black),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Image.asset(
                      genderImage,
                      height: 50,
                      width: 50,
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}