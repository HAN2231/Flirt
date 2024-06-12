import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _unreadMessageCountController = StreamController<int>.broadcast();
  Stream<int> get unreadMessageCountStream => _unreadMessageCountController.stream;
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;
  List<StreamSubscription<QuerySnapshot>> _messageSubscriptions = [];

  void subscribeToChatRooms() {
    String currentUserId = _auth.currentUser?.uid ?? "";

    _chatRoomsSubscription = _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: currentUserId)
        .snapshots()
        .listen((chatRoomsSnapshot) {
      // 이전 메시지 구독을 모두 취소
      for (var subscription in _messageSubscriptions) {
        subscription.cancel();
      }
      _messageSubscriptions.clear();

      int count = 0;

      if (chatRoomsSnapshot.docs.isEmpty) {
        _unreadMessageCountController.add(count);
        return;
      }

      for (var chatRoom in chatRoomsSnapshot.docs) {
        var messageSubscription = chatRoom.reference
            .collection('messages')
            .where('receiverID', isEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .snapshots()
            .listen((unreadMessagesSnapshot) {
          count += unreadMessagesSnapshot.docs.length;
          _unreadMessageCountController.add(count);
        });

        _messageSubscriptions.add(messageSubscription);
      }
    });
  }

  void dispose() {
    _chatRoomsSubscription?.cancel();
    for (var subscription in _messageSubscriptions) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
  }
}