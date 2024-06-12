import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String? imageUrl;
  final String? timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.imageUrl,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isCurrentUser && timestamp != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 22, 0, 0),
                child: Text(
                  timestamp!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            Container(
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.green[500] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                  maxHeight: 200,
                ),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                ),
              )
                  : Text(
                  "  " + message + "  ",
                  style: isCurrentUser
                      ? TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp)
                      : TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp)),
            ),
            if (!isCurrentUser && timestamp != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 22, 8, 0),
                child: Text(
                  timestamp!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ],
    );
  }
}