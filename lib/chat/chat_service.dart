import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/message.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<int> _getChatCount(String chatRoomID, String userID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('chatCount_${chatRoomID}_$userID') ?? 20;
  }

  Future<void> _setChatCount(String chatRoomID, String userID, int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatCount_${chatRoomID}_$userID', count);
  }

  Future<void> sendMessage(String voteId, String receiverID, String message, String currentUserID, String greeting) async {
    String chatRoomID = voteId;

    int chatCount = await _getChatCount(chatRoomID, currentUserID);

    if (chatCount <= 0) {
      // 채팅 횟수가 0이하라면 메시지를 전송하지 않음
      return;
    }

    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      timestamp: timestamp,
      message: message,
      greeting: greeting,
      imageUrl: '',
      isRead: false,  // 여기 추가
    );

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());

    await _firestore.collection('chat_rooms').doc(chatRoomID).set({
      'lastMessage': message,
      'lastTimestamp': timestamp,
      'users': [currentUserID, receiverID],
      'greeting': greeting,
      'isRead': false,  // 여기 추가
    }, SetOptions(merge: true));

    chatCount--;
    await _setChatCount(chatRoomID, currentUserID, chatCount);
  }

  Future<void> sendImage(String voteId, String receiverID, String imagePath, String currentUserID, String greeting) async {
    String chatRoomID = voteId;

    int chatCount = await _getChatCount(chatRoomID, currentUserID);

    if (chatCount <= 0) {
      // 채팅 횟수가 0이하라면 이미지를 전송하지 않음
      return;
    }

    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = _storage.ref().child('chat_images').child(fileName);
    UploadTask uploadTask = reference.putFile(File(imagePath));
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      timestamp: timestamp,
      message: '[Image]',
      imageUrl: imageUrl,
      greeting: greeting,
      isRead: false,  // 여기 추가
    );

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());

    await _firestore.collection('chat_rooms').doc(chatRoomID).set({
      'lastMessage': '[Image]',
      'lastTimestamp': timestamp,
      'users': [currentUserID, receiverID],
      'greeting': greeting,
      'isRead': false,  // 여기 추가
    }, SetOptions(merge: true));

    chatCount--;
    await _setChatCount(chatRoomID, currentUserID, chatCount);
  }

  Future<bool> deductPoints(String userId, int points) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception("User does not exist!");
      }

      int currentPoints = snapshot['points'];
      if (currentPoints >= points) {
        transaction.update(userRef, {'points': currentPoints - points});
        return true;
      } else {
        return false;
      }
    });
  }

  Future<bool> isChatRoomExists(String chatRoomId) async {
    DocumentSnapshot chatRoomSnapshot = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
    return chatRoomSnapshot.exists;
  }

  Stream<QuerySnapshot> getMessages(String chatRoomID) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatRooms(String userID) {
    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: userID)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }
}