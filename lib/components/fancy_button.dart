
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FancyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color backgroundColor; // 추가된 부분

  const FancyButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.textColor = Colors.black,
    this.backgroundColor = const Color(0xffF2F1F3), // 기본 배경색 설정
  }) : super(key: key);

  @override
  _FancyButtonState createState() => _FancyButtonState();
}

class _FancyButtonState extends State<FancyButton> {
  bool _hasVoted = false; // 투표 여부를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _hasVoted ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(
          fontSize: 16.sp,
        ),
        foregroundColor: widget.textColor,
        backgroundColor: _hasVoted? Colors.grey : widget.backgroundColor, // 배경색 설정
        elevation: 0,
        minimumSize: const Size(350, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 모서리의 곡률을 조정합니다.
        ),
      ),
      child: Text(widget.text),
    );
  }

  void setVoted() {
    setState(() {
      _hasVoted = true;
    });
  }
}