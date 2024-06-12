import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MakeVotePage extends StatefulWidget {
  @override
  _MakeVotePage createState() => _MakeVotePage();
}

class _MakeVotePage extends State<MakeVotePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _questionController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(_checkIfButtonShouldBeEnabled);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _checkIfButtonShouldBeEnabled() {
    setState(() {
      _isButtonEnabled = _questionController.text.trim().isNotEmpty;
    });
  }

  Future<void> _submitQuestion(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('questions').add({
        'question': _questionController.text,
        'userId': currentUser.uid,
        'timestamp': Timestamp.now(),
      }).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('질문이 제출되었습니다!')),
        );
      }).catchError((error) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $error')),
        );
      });
    }
  }

  void _showSubmitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '질문 제출',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            '비속어나 욕설 사용 시 앱 사용에 제한이 있을 수 있습니다.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[700],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              child: Text('제출',style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white
              ),),
              onPressed: () {
                Navigator.of(context).pop();
                _submitQuestion(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.only(
          bottom: 100,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Wrap(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '나만의 질문을 만들어보세요',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    '작성한 질문지는 관리자가 검토 후 반영됩니다.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    padding: EdgeInsets.all(15),
                    controller: _questionController,
                    placeholder: '질문지 작성...',
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
                  SizedBox(height: 25.0),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isButtonEnabled
                          ? () {
                        _showSubmitDialog(context);
                      }
                          : null,
                      label: Text(
                        '질문 저장',
                        style: TextStyle(
                            color:
                            _isButtonEnabled ? Colors.white : Colors.grey,
                            fontSize: 15.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isButtonEnabled ? Colors.blue : Colors.grey,
                        padding: EdgeInsets.symmetric(
                            horizontal: 32.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}