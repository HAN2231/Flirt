import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollsUploadPage extends StatefulWidget {
  const PollsUploadPage({Key? key}) : super(key: key);

  @override
  _PollsUploadPage createState() => _PollsUploadPage();
}

class _PollsUploadPage extends State<PollsUploadPage> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _vote1Controller = TextEditingController();
  final TextEditingController _vote2Controller = TextEditingController();
  bool _isButtonEnabled = false;
  final int _postPoints = 30; // 포스트 업로드 시 제공할 포인트

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_checkIfButtonShouldBeEnabled);
    _vote1Controller.addListener(_checkIfButtonShouldBeEnabled);
    _vote2Controller.addListener(_checkIfButtonShouldBeEnabled);
  }

  void _checkIfButtonShouldBeEnabled() {
    setState(() {
      _isButtonEnabled = _captionController.text.trim().isNotEmpty &&
          _vote1Controller.text.trim().isNotEmpty &&
          _vote2Controller.text.trim().isNotEmpty;
    });
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _checkIfButtonShouldBeEnabled();
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadPost() async {
    setState(() {
      _isButtonEnabled = false;
      Navigator.of(context).pop();
    });

    String imageUrl = ''; // 이미지 URL 초기화

    // 이미지가 선택되었는지 확인
    if (_image != null) {
      imageUrl = await uploadImageToStorage(); // 이미지가 있을 경우에만 업로드
    }

    String caption = _captionController.text.trim();
    String vote1 = _vote1Controller.text.trim();
    String vote2 = _vote2Controller.text.trim();
    int initialVote1Count = 0;
    int initialVote2Count = 0;

    // Get current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Get current user's major from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    String major = userSnapshot['major'];

    // Upload the post to Firebase Firestore
    await FirebaseFirestore.instance.collection('posts').add({
      'imageUrl': imageUrl, // 이미지 URL이 있거나 없을 수 있습니다.
      'caption': caption,
      'timestamp': Timestamp.now(),
      'uid': uid, // 사용자의 UID 저장
      'vote_1': vote1,
      'vote_2': vote2,
      'major': major,
      'vote_1_count': initialVote1Count,
      'vote_2_count': initialVote2Count,
    });

    // 포인트 업데이트
    await _updateUserPoints(uid);

    // Navigate back to the previous screen
    Navigator.pop(context);
  }

  Future<void> _updateUserPoints(String userId) async {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception("사용자 문서가 존재하지 않습니다.");
      }

      int newPoints = (snapshot.data() as Map<String, dynamic>)['points'] + _postPoints;
      transaction.update(userRef, {'points': newPoints});
    });

    // 포인트 획득 기록을 현재 사용자 문서 아래 points 하위 컬렉션에 저장
    await FirebaseFirestore.instance.collection('users').doc(userId).collection('points').add({
      'pointsource': 'polls',
      'points': _postPoints,
      'pointtimestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadImageToStorage() async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference reference = firebase_storage.FirebaseStorage.instance.ref().child('images/$fileName');
      await reference.putFile(_image!);
      String imageUrl = await reference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // size 변수를 여기서 정의

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '만들기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          if (_image != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: size.height * 0.1 + 20, // 업로드 및 게시하기 버튼을 고려하여 이미지 크기 조정
              child: Image.file(
                _image!,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 60),
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: CupertinoTextField(
                              textAlign: TextAlign.center,
                              padding: EdgeInsets.all(15),
                              controller: _captionController,
                              placeholder: '내용을 입력해주세요...',
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(30),
                              ],
                              placeholderStyle: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20
                              ),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                border: Border.all(
                                  color: CupertinoColors.white,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              cursorColor: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                        SizedBox(height: 355),
                        Container(
                          width: size.width * 0.95,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF2F1F3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: _vote1Controller,
                                  placeholder: '선택지 1',
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  placeholderStyle: TextStyle(color: Colors.grey),
                                  style: TextStyle(color: Colors.black),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.extraLightBackgroundGray,
                                    border: Border.all(
                                      color: CupertinoColors.extraLightBackgroundGray,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  cursorColor: CupertinoColors.systemGrey,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF2F1F3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: _vote2Controller,
                                  placeholder: '선택지 2',
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  placeholderStyle: TextStyle(color: Colors.grey),
                                  style: TextStyle(color: Colors.black),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.extraLightBackgroundGray,
                                    border: Border.all(
                                      color: CupertinoColors.extraLightBackgroundGray,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  cursorColor: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: getImage,
                        icon: Icon(Icons.photo_library, size: 24, color: Colors.white,),
                        label: Text('업로드',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(15),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isButtonEnabled ? uploadPost : null,
                        child: Text('게시하기',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(15),
                          backgroundColor: _isButtonEnabled ? Colors.blue : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _vote1Controller.dispose();
    _vote2Controller.dispose();
    super.dispose();
  }
}
