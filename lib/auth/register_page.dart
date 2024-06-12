import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:logintest/components/my_button.dart';
import 'package:logintest/components/square_tile.dart';
import 'package:logintest/services/auth_service.dart';
import 'package:logintest/components/departments.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../profile/setting/privacy_policy_page.dart';
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
  bool _termsAccepted1 = false;
  bool _termsAccepted2 = false;
  bool _termsAccepted3 = false;
  bool _termsAccepted4 = false;
  bool _isPasswordWeak = false; // 약한 비밀번호 여부

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
          _isButtonEnabled = emailController.text.isNotEmpty && _isValidEmail(emailController.text);
          _emailError = null;
          break;
        case 1:
          _isButtonEnabled = passwordController.text.isNotEmpty && confirmPasswordController.text.isNotEmpty;
          _passwordsMatch = passwordController.text == confirmPasswordController.text;
          _isPasswordWeak = _isWeakPassword(passwordController.text);
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
          _isButtonEnabled = true; // Gender selection page
          break;
        case 6:
          _isButtonEnabled = _termsAccepted1 && _termsAccepted2 && _termsAccepted3 && _termsAccepted4;
          break;
        default:
          _isButtonEnabled = true;
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[0-9]+$'); // 숫자만 입력 가능
    return emailRegExp.hasMatch(email);
  }

  bool _isWeakPassword(String password) {
    return password.length < 8;
  }

  Future<void> addUserDetails(String uid, String firstName, String lastName,
      String email, int age, String? department, String? major, String gender) async {
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
      'gender': gender,
      'points': 100,
      'premium': 'off',
    });
  }

  Future<bool> _isEmailAlreadyInUse(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> signUserUp() async {
    if (!mounted) return;

    try {
      final email = "${emailController.text.trim()}@gm.hannam.ac.kr";

      if (await _isEmailAlreadyInUse(email)) {
        showErrorMessage("학번을 확인해 주세요.");
        _navigateToPage(0); // Navigate back to the email input page
        return;
      }

      if (passwordController.text == confirmPasswordController.text) {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: passwordController.text.trim(),
        );

        await addUserDetails(
          userCredential.user!.uid,
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          email,
          int.parse(ageController.text.trim()),
          _selectedDepartment,
          _selectedMajor,
          _selectedGender,
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(onTap: widget.onTap)),
          );
        }
      } else {
        showErrorMessage("비밀번호가 일치하지 않습니다.");
        _navigateToPage(1); // Navigate back to the password input page
      }
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.code);
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black,fontWeight: FontWeight.w500),
            ),
          ),
        );
      },
    );
  }

  void nextPage() {
    if (_currentPage == 0 && !_isValidEmail(emailController.text)) {
      setState(() {
        _emailError = '잘못된 학번입니다.';
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

  void _navigateToPage(int page) {
    setState(() {
      _currentPage = page;
      _pageController.jumpToPage(page);
      _checkIfButtonShouldBeEnabled();
    });
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

  void _toggleTermsAccepted1(bool? value) {
    setState(() {
      _termsAccepted1 = value ?? false;
      _checkIfButtonShouldBeEnabled();
    });
  }

  void _toggleTermsAccepted2(bool? value) {
    setState(() {
      _termsAccepted2 = value ?? false;
      _checkIfButtonShouldBeEnabled();
    });
  }

  void _toggleTermsAccepted3(bool? value) {
    setState(() {
      _termsAccepted3 = value ?? false;
      _checkIfButtonShouldBeEnabled();
    });
  }

  void _toggleTermsAccepted4(bool? value) {
    setState(() {
      _termsAccepted4 = value ?? false;
      _checkIfButtonShouldBeEnabled();
    });
  }

  Future<void> _showPrivacyPolicyPage() async {
    await showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white, // Ensure the background color is not transparent
              ),
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.9,
              child: PrivacyPolicyPage(),
            ),
          ),
        );
      },
    );
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
                                  suffix: Text('@gm.hannam.ac.kr                     ',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),),
                                  padding: EdgeInsets.all(15),
                                  controller: emailController,
                                  placeholder: '학번',
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(8),
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
                              if (_emailError != null) ...[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _emailError!,
                                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                                  ),
                                ),
                              ],
                              SizedBox(height: 10),

                            ],
                          ),
                          "다음",
                        ),
                        buildPage(
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.centerRight,
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
                                ],
                              ),
                              SizedBox(height: 10.sp),
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
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
                                          color: confirmPasswordController.text.isEmpty || (_passwordsMatch && !_isPasswordWeak) ? CupertinoColors.extraLightBackgroundGray : Colors.red,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      cursorColor: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                  if (_passwordsMatch && confirmPasswordController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                    ),
                                ],
                              ),
                              if (confirmPasswordController.text.isNotEmpty && !_passwordsMatch)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '비밀번호가 일치하지 않습니다',
                                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                                  ),
                                ),
                              if (_isPasswordWeak)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '비밀번호가 너무 약합니다. 8자 이상으로 설정해주세요.',
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
                                    LengthLimitingTextInputFormatter(10),
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
                              SizedBox(height: 10.h),
                              Text(
                                '이름은 한번 입력하면 다시 바꿀 수 없습니다.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.sp,
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
                              buildTermsRow(_termsAccepted1, "한남대 학생이에요.", _toggleTermsAccepted1),
                              SizedBox(height: 10,),
                              buildTermsRowWithArrow(_termsAccepted2, "제3자 정보제공에 동의해요.", _toggleTermsAccepted2),
                              SizedBox(height: 10,),
                              buildTermsRowWithArrow(_termsAccepted3, "개인정보 처리방침에 동의해요.", _toggleTermsAccepted3),
                              SizedBox(height: 10,),
                              buildTermsRowWithArrow(_termsAccepted4, "서비스 이용약관에 동의해요", _toggleTermsAccepted4),
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
                              color: Colors.grey[400]),
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
        return '학교 이메일을 입력해주세요';
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
        return '약관에 동의해주세요';
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
              '< 이전으로 돌아가기',
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

  Widget buildTermsRow(bool isChecked, String text, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.5,
          child: Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            activeColor: Colors.white,
            checkColor: Colors.blue,
            value: isChecked,
            onChanged: onChanged,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTermsRowWithArrow(bool isChecked, String text, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.5,
          child: Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            activeColor: Colors.white,
            checkColor: Colors.blue,
            value: isChecked,
            onChanged: onChanged,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16.sp),
                onPressed: _showPrivacyPolicyPage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}