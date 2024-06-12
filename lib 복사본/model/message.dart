import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final String greeting;
  final String? imageUrl;  // 이미지 URL 필드 추가, 기본값 null
  final bool isRead;  // 읽음 상태 필드 추가

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    required this.greeting,
    this.imageUrl,  // 선택적 필드로 지정, 기본값 null
    this.isRead = false,  // 기본값 false로 지정
  });

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'greeting': greeting,
      'imageUrl': imageUrl,  // 맵에 이미지 URL 추가
      'isRead': isRead,  // 읽음 상태 추가
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'],
      senderEmail: map['senderEmail'],
      receiverID: map['receiverID'],
      message: map['message'],
      timestamp: map['timestamp'],
      greeting: map['greeting'],
      imageUrl: map['imageUrl'],  // 이미지 URL 추가
      isRead: map['isRead'],  // 읽음 상태 추가
    );
  }
}