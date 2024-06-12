import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String? profileImagePath;
  final String? imageUrl;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.profileImagePath,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: profileImagePath != null
                ? Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                backgroundImage: AssetImage(profileImagePath!),
              ),
            )
                : SizedBox(width: 40),
          ),
        Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.green : Colors.grey.shade500,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
