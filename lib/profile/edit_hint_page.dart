import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class EditHintPage extends StatefulWidget {
  final String hint1;
  final String hint2;
  final String hint3;

  EditHintPage({
    required this.hint1,
    required this.hint2,
    required this.hint3,
  });

  @override
  _EditHintPage createState() => _EditHintPage();
}

class _EditHintPage extends State<EditHintPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _hint1Controller;
  late TextEditingController _hint2Controller;
  late TextEditingController _hint3Controller;

  @override
  void initState() {
    super.initState();
    _hint1Controller = TextEditingController(text: widget.hint1);
    _hint2Controller = TextEditingController(text: widget.hint2);
    _hint3Controller = TextEditingController(text: widget.hint3);
  }

  @override
  void dispose() {
    _hint1Controller.dispose();
    _hint2Controller.dispose();
    _hint3Controller.dispose();
    super.dispose();
  }

  Future<void> _updateUserData(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'userhint1': _hint1Controller.text,
        'userhint2': _hint2Controller.text,
        'userhint3': _hint3Controller.text,
      }).then((_) {
        Navigator.pop(context, {
          'hint1': _hint1Controller.text,
          'hint2': _hint2Controller.text,
          'hint3': _hint3Controller.text,
        });
      }).catchError((error) {
        // Handle error
      });
    }
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
          bottom: MediaQuery.of(context).viewInsets.bottom + 15,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프로필 힌트를 수정',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    '힌트는 두 자리만 입력 가능해요',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    padding: EdgeInsets.all(15),
                    controller: _hint1Controller,
                    placeholder: '힌트 1',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2),
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
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    padding: EdgeInsets.all(15),
                    controller: _hint2Controller,
                    placeholder: '힌트 2',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2),
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
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    padding: EdgeInsets.all(15),
                    controller: _hint3Controller,
                    placeholder: '힌트 3',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2),
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
                      onPressed: () {
                        _updateUserData(context);
                      },
                      label: Text(
                        '힌트 저장',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
