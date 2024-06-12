import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logintest/components/my_button.dart';
import 'package:logintest/components/square_tile.dart';
import 'package:logintest/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// text editing controllers
class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ScreenUtil 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenUtil.init(
          context,
          designSize: Size(360, 690),
        );
      }
    });
  }

  // sign user in method
  void signUserIn() async {
    if (!mounted) return; // 위젯이 이미 해제된 경우 작업을 중단합니다.

    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Firebase에 사용자 로그인 정보를 보냅니다.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // 비동기 작업 완료 후에는 위젯이 여전히 마운트된 상태인지 확인합니다.
      if (mounted) {
        // 비동기 작업이 완료되었으므로 로딩 다이얼로그를 닫습니다.
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // 비동기 작업 완료 후에는 위젯이 여전히 마운트된 상태인지 확인합니다.
      if (mounted) {
        // 비동기 작업이 완료되었으므로 로딩 다이얼로그를 닫습니다.
        Navigator.pop(context);
        // 오류 메시지를 표시합니다.
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "로그인 실패",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: Text("로그인 중 오류가 발생했습니다.",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "확인",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo
                Container(
                  margin: EdgeInsets.only(top: 50),
                  height: 110,
                  width: 110,
                  child: Image.asset(
                    'assets/ef.png',
                  ),
                ),

                const SizedBox(height: 30),

                // welcome back, you've been missed!
                Text(
                  '누가 NULL 좋아하는지 알려줄게',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 25),

                // email textfield
                Container(
                  width: 340,
                  child: CupertinoTextField(
                    padding: EdgeInsets.all(15),
                    controller: emailController,
                    placeholder: '이메일',
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

                const SizedBox(height: 10),

                // password textfield
                Container(
                  width: 340,
                  child: CupertinoTextField(
                    padding: EdgeInsets.all(15),
                    controller: passwordController,
                    placeholder: '비밀번호',
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
                    obscureText: true,
                  ),
                ),

                const SizedBox(height: 30),

                // sign in button
                MyButton(
                  text: "로그인",
                  onTap: signUserIn,
                ),
                SizedBox(
                  height: 9.5,
                ),
                // forgot password?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '비밀번호 재설정',
                        style: TextStyle(color: Colors.grey[600],
                        decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 140),

                // or continue with
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          '소셜 로그인',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                // google + apple sign in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // google button
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(),
                      imagePath: 'assets/google.png',
                    ),
                    SizedBox(width: 25),
                    // apple button
                    SquareTile(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'assets/apple.png'),
                  ],
                ),
                SizedBox(height: 18),
                // not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '처음이신가요?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        '회원가입 하기',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}