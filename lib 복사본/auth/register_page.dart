import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:logintest/components/my_button.dart';
import 'package:logintest/components/my_textfield.dart';
import 'package:logintest/components/square_tile.dart';
import 'package:logintest/services/auth_service.dart';
import 'package:logintest/components/departments.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  const RegisterPage({Key? key, required this.onTap}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedMajor;
  String _selectedGender = '남자';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isButtonEnabled = false;
  bool _passwordsMatch = true;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_checkIfButtonShouldBeEnabled);
    passwordController.addListener(_checkIfButtonShouldBeEnabled);
    confirmPasswordController.addListener(_checkIfButtonShouldBeEnabled);
    firstNameController.addListener(_checkIfButtonShouldBeEnabled);
    lastNameController.addListener(_checkIfButtonShouldBeEnabled);
    ageController.addListener(_checkIfButtonShouldBeEnabled);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _checkIfButtonShouldBeEnabled() {
    setState(() {
      switch (_currentPage) {
        case 0:
          _isButtonEnabled = emailController.text.isNotEmpty;
          _emailError = null;
          break;
        case 1:
          _isButtonEnabled = passwordController.text.isNotEmpty && confirmPasswordController.text.isNotEmpty;
          _passwordsMatch = passwordController.text == confirmPasswordController.text;
          break;
        case 2:
          _isButtonEnabled = firstNameController.text.isNotEmpty;
          break;
        case 3:
          _isButtonEnabled = ageController.text.isNotEmpty;
          break;
        case 4:
          _isButtonEnabled = _selectedDepartment != null && _selectedMajor != null;
          break;
        case 5:

          break;
        default:
          _isButtonEnabled = true;
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegExp.hasMatch(email);
  }

  Future<void> addUserDetails(String uid, String firstName, String lastName,
      String email, int age, String? department, String? major, String? fcmToken, String gender) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'firstname': firstName,
      'last name': lastName,
      'email': email,
      'age': age,
      'department': department,
      'major': major,
      'userhint1': '',
      'userhint2': '',
      'userhint3': '',
      'fcmToken': fcmToken,
      'gender': gender,
      'points': 100,
      'premium': 'off',
    });
  }

  Future<String?> _getUserFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> signUserUp() async {
    if (!mounted) return;

    try {
      if (passwordController.text == confirmPasswordController.text) {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: emailController.text.trim(),
        );

        String? fcmToken = await _getUserFCMToken();

        await addUserDetails(
          userCredential.user!.uid,
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          emailController.text.trim(),
          int.parse(ageController.text.trim()),
          _selectedDepartment,
          _selectedMajor,
          fcmToken,
          _selectedGender,
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(onTap: widget.onTap)),
          );
        }
      } else {
        Navigator.pop(context);
        showErrorMessage("비밀번호가 일치하지 않습니다.");
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void nextPage() {
    if (_currentPage == 0 && !_isValidEmail(emailController.text)) {
      setState(() {
        _emailError = '잘못된 이메일 주소입니다.';
      });
    } else {
      setState(() {
        _emailError = null;
      });
      if (_currentPage < 7) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Future<void> _showDepartmentBottomSheet() async {
    final selectedDepartment = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            children: <Widget>[
              for (var i = 0; i < departments.keys.length; i++)
                Column(
                  children: [
                    ListTile(
                      title: Text(
                        departments.keys.elementAt(i),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      dense: true,
                      visualDensity: VisualDensity(vertical: -3),
                      onTap: () {
                        Navigator.pop(context, departments.keys.elementAt(i));
                      },
                    ),
                    if (i < departments.keys.length - 1) Divider(),
                  ],
                ),
            ],
          ),
        );
      },
    );

    if (selectedDepartment != null) {
      setState(() {
        _selectedDepartment = selectedDepartment;
        _selectedMajor = null;
      });
    }
  }

  Future<void> _showMajorBottomSheet() async {
    final selectedMajor = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        if (_selectedDepartment == null) {
          return Center(child: Text("학부를 먼저 선택해주세요"));
        }
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          child: ListView(
            padding: EdgeInsets.all(8),
            shrinkWrap: true,
            children: <Widget>[
              for (var i = 0; i < departments[_selectedDepartment]!.length; i++)
                Column(
                  children: [
                    ListTile(
                      title: Text(
                        departments[_selectedDepartment]![i],
                        style: TextStyle(
                          fontSize: 14.sp,
                        ),
                      ),
                      dense: true,
                      visualDensity: VisualDensity(vertical: -3),
                      onTap: () {
                        Navigator.pop(context, departments[_selectedDepartment]![i]);
                      },
                    ),
                    if (i < departments[_selectedDepartment]!.length - 1) Divider(),
                  ],
                ),
            ],
          ),
        );
      },
    );

    if (selectedMajor != null) {
      setState(() {
        _selectedMajor = selectedMajor;
        _isButtonEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 25.h),
                  LinearProgressIndicator(
                      value: (_currentPage + 1) / 7,
                      minHeight: 8.0,
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.blue
                  ),
                  SizedBox(height: 25.h),
                  Text(
                    getTextForCurrentPage(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 25.h),
                  Container(
                    height: 370.h,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                          _checkIfButtonShouldBeEnabled();
                        });
                      },
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        buildPage(
                          Column(
                            children: [
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
                              if (_emailError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _emailError!,
                                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          "다음",
                        ),
                        buildPage(
                          Column(
                            children: [
                              Container(
                                width: 340,
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: passwordController,
                                  placeholder: '비밀번호',
                                  obscureText: true,
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
                              SizedBox(height: 10.sp),
                              Container(
                                width: 340,
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: confirmPasswordController,
                                  placeholder: '비밀번호 확인',
                                  obscureText: true,
                                  placeholderStyle: TextStyle(color: Colors.grey),
                                  style: TextStyle(color: Colors.black),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.extraLightBackgroundGray,
                                    border: Border.all(
                                      color: confirmPasswordController.text.isEmpty || _passwordsMatch ? CupertinoColors.extraLightBackgroundGray : Colors.red,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  cursorColor: CupertinoColors.systemGrey,
                                ),
                              ),
                              if (confirmPasswordController.text.isNotEmpty && !_passwordsMatch)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '비밀번호가 일치하지 않습니다',
                                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                                  ),
                                ),
                            ],
                          ),
                          "다음",
                        ),
                        buildPage(
                          Column(
                            children: [
                              Container(
                                width: 340,
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: firstNameController,
                                  placeholder: '이름',
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(5),
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
                          "다음",
                        ),
                        buildPage(
                          Column(
                            children: [
                              Container(
                                width: 340,
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: ageController,
                                  placeholder: '나이',
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
                              ),
                            ],
                          ),
                          "다음",
                        ),
                        buildPage(
                          Container(
                            width: 340,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: _showDepartmentBottomSheet,
                                  child: Container(
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.extraLightBackgroundGray,
                                      border: Border.all(
                                        color: CupertinoColors.extraLightBackgroundGray,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDepartment ?? '학부 선택',
                                          style: TextStyle(
                                            color: _selectedDepartment == null ? Colors.grey : Colors.black,
                                            fontSize: 16.sp,
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.sp),
                                InkWell(
                                  onTap: _selectedDepartment == null ? null : _showMajorBottomSheet,
                                  child: Container(
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.extraLightBackgroundGray,
                                      border: Border.all(
                                        color: CupertinoColors.extraLightBackgroundGray,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedMajor ?? '전공 선택',
                                          style: TextStyle(
                                            color: _selectedMajor == null ? Colors.grey : Colors.black,
                                            fontSize: 16.sp,
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          "다음",
                        ),
                        buildPage(
                          Container(
                            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = '남자';
                                      _isButtonEnabled = true;
                                    });
                                  },
                                  child: Container(
                                    width: 157.w,
                                    height: 60.h,
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: _selectedGender == '남자' ? Color(0xff91a0e2) : CupertinoColors.extraLightBackgroundGray,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '남자',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedGender == '남자' ? Colors.black : Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = '여자';
                                      _isButtonEnabled = true;
                                    });
                                  },
                                  child: Container(
                                    width: 157.w,
                                    height: 60.h,
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: _selectedGender == '여자' ? Color(0xfff36a8d) : CupertinoColors.extraLightBackgroundGray,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '여자',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedGender == '여자' ? Colors.black : Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          "다음",
                        ),
                        buildPage(
                          Column(
                            children: [
                              Container(
                                width: 340,
                                child: CupertinoTextField(
                                  padding: EdgeInsets.all(15),
                                  controller: ageController,
                                  placeholder: '나이',
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
                              ),
                            ],
                          ),
                          "Flirt 시작하기",
                          onTap: signUserUp,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
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
                  SizedBox(height: 5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'assets/google.png',
                      ),
                      SizedBox(width: 25.w),
                      SquareTile(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'assets/apple.png',
                      )
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있습니까?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          '로그인 하기',
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
      ),
    );
  }

  String getTextForCurrentPage() {
    switch (_currentPage) {
      case 0:
        return '이메일을 입력해주세요';
      case 1:
        return '비밀번호를 입력해주세요';
      case 2:
        return '이름을 입력해주세요';
      case 3:
        return '나이를 입력해주세요';
      case 4:
        return '학부 및 전공을 선택해주세요';
      case 5:
        return '성별을 선택해주세요';
      case 6:
        return '회원가입을 완료해주세요';
      default:
        return '계정을 생성해보세요!';
    }
  }

  Widget buildPage(Widget child, String buttonText, {VoidCallback? onTap}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: child),
        SizedBox(height: 25.h),
        MyButton(
          text: buttonText,
          onTap: _isButtonEnabled ? (onTap != null ? onTap : nextPage) : null,
          isEnabled: _isButtonEnabled,
        ),
        SizedBox(height: 10.h),
        if (_currentPage > 0)
          GestureDetector(
            onTap: previousPage,
            child: Text(
              '이전으로 돌아가기',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ),
        if (_currentPage == 0)
          Text(
            'Flirt를 시작하기 위해 정보를 입력해주세요',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
      ],
    );
  }
}
