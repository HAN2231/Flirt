import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ranking Page'),
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('votes')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          Map<String, Map<String, int>> questionVotes = {};

          snapshot.data!.docs.forEach((doc) {
            String receiverID = doc['receiverID'];
            String greeting = doc['greeting'];

            if (!questionVotes.containsKey(greeting)) {
              questionVotes[greeting] = {};
            }
            questionVotes[greeting]?[receiverID] =
                (questionVotes[greeting]?[receiverID] ?? 0) + 1;
          });

          // 질문을 투표 수에 따라 내림차순으로 정렬
          List<MapEntry<String, Map<String, int>>> sortedQuestions =
          questionVotes.entries.toList()
            ..sort((a, b) =>
                b.value.length.compareTo(a.value.length));

          return ListView.builder(
            itemCount: sortedQuestions.length,
            itemBuilder: (context, index) {
              String greeting = sortedQuestions[index].key;
              Map<String, int> voteCountMap = sortedQuestions[index].value;

              List<String> topUsers = [];
              List<int> voteCounts = [];
              voteCountMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value))
                ..forEach((entry) {
                  topUsers.add(entry.key);
                  voteCounts.add(entry.value);
                });

              return Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question: $greeting',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: topUsers.length,
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(topUsers[index])
                                    .get(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }

                                  var userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                                  String userName = userData['firstname'];

                                  return ListTile(
                                    title: Text(userName),
                                    subtitle: Text('${voteCounts[index]} votes'),
                                  );
                                },
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 10,
                                width: voteCounts[index] * 10.0,
                                color: Colors.blue,
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
