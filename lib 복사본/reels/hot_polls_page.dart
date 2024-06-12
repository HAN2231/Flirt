import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logintest/reels/hot_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HotPollsPage extends StatelessWidget {
  const HotPollsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '인기 폴스',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(color: Colors.white,);
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hot polls available'));
          }

          final posts = snapshot.data!.docs
              .map((doc) => doc)
              .where((post) {
            final vote1Count = post['vote_1_count'];
            final vote2Count = post['vote_2_count'];
            final totalVotes = vote1Count + vote2Count;
            return totalVotes > 3;
          })
              .toList();

          // 카드 정렬
          posts.sort((a, b) {
            final vote1CountA = a['vote_1_count'];
            final vote2CountA = a['vote_2_count'];
            final totalVotesA = vote1CountA + vote2CountA;

            final vote1CountB = b['vote_1_count'];
            final vote2CountB = b['vote_2_count'];
            final totalVotesB = vote1CountB + vote2CountB;

            return totalVotesB.compareTo(totalVotesA); // 내림차순 정렬
          });

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post.id;
              final imageUrl = post['imageUrl'];
              final caption = post['caption'];
              final vote1Count = post['vote_1_count'];
              final vote2Count = post['vote_2_count'];
              final totalVotes = vote1Count + vote2Count;
              final postTime = post['timestamp'].toDate();
              final now = DateTime.now();
              final difference = now.difference(postTime);
              String timeAgoMessage = '';

              if (difference.inSeconds < 60) {
                timeAgoMessage = '${difference.inSeconds}초 전';
              } else if (difference.inMinutes < 60) {
                timeAgoMessage = '${difference.inMinutes}분 전';
              } else if (difference.inHours < 24) {
                timeAgoMessage = '${difference.inHours}시간 전';
              } else if (difference.inDays < 7) {
                timeAgoMessage = '${difference.inDays}일 전';
              } else {
                int weeks = (difference.inDays / 7).floor();
                timeAgoMessage = '$weeks주일 전';
              }

              return Card(
                color: Color(0xF8F7F9FF),
                elevation: 0,
                margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotPage(postId: postId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/ef.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            'assets/ef.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caption,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 35),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total votes: $totalVotes'),
                                  Text(timeAgoMessage),
                                ],
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
        },
      ),
    );
  }
}
