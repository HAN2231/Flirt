import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckVoterPage extends StatefulWidget {
  final String voterId;

  const CheckVoterPage({Key? key, required this.voterId}) : super(key: key);

  @override
  _CheckVoterPageState createState() => _CheckVoterPageState();
}

class _CheckVoterPageState extends State<CheckVoterPage> {
  Map<String, dynamic>? _voterData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<bool> _buttonEnabled = [];
  List<bool> _buttonRevealed = [];

  @override
  void initState() {
    super.initState();
    _fetchVoterData();
  }

  Future<void> _fetchVoterData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DocumentSnapshot voterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.voterId)
          .get();
      if (voterDoc.exists) {
        setState(() {
          _voterData = voterDoc.data() as Map<String, dynamic>?;
          _isLoading = false;
          _buttonEnabled = List.generate(
              _voterData!['firstname'].length,
                  (index) => prefs.getBool('${widget.voterId}_buttonEnabled_$index') ?? true);
          _buttonRevealed = List.generate(
              _voterData!['firstname'].length,
                  (index) => prefs.getBool('${widget.voterId}_buttonRevealed_$index') ?? false);
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getInitial(String name, int index) {
    const List<String> initials = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];

    int charCode = name.codeUnitAt(index) - 0xAC00;
    if (charCode >= 0 && charCode <= 11172) {
      int initialIndex = charCode ~/ 588;
      return initials[initialIndex];
    }
    return name[index];
  }

  void _onPressed(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < _buttonEnabled.length; i++) {
        _buttonEnabled[i] = i == index;
        _buttonRevealed[i] = i == index;
        prefs.setBool('${widget.voterId}_buttonEnabled_$i', _buttonEnabled[i]);
        prefs.setBool('${widget.voterId}_buttonRevealed_$i', _buttonRevealed[i]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    if (_voterData == null) {
      return const Center(child: Text('Voter data not found.'));
    }

    final voterData = _voterData!;
    final firstName = voterData['firstname'] ?? 'No name';
    final major = voterData['major'] ?? 'No major';
    final gender = voterData['gender'] ?? 'No gender';
    final hint1 = voterData['hint1'] ?? '';
    final hint2 = voterData['hint2'] ?? '';
    final hint3 = voterData['hint3'] ?? '';

    final imagePath =
    gender == '남자' ? 'assets/men.png' : 'assets/female.png';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '투표를 보낸 사람의 초성은?',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '하나의 초성만 확인 가능합니다!',
              style: TextStyle(color: Colors.grey[700], fontSize: 16.sp),
            ),
            SizedBox(height: 30),
            Container(
              margin: EdgeInsets.all(10),
              child: CircleAvatar(
                backgroundImage: AssetImage(imagePath),
                radius: 50,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  major,
                  style: TextStyle(fontSize: 20.sp),
                ),
                SizedBox(width: 10),
                Text(
                  '#$hint1 #$hint2 #$hint3',
                  style: TextStyle(fontSize: 20.sp),
                ),
              ],
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: List.generate(firstName.length, (index) {
                return _InitialButton(
                  index: index,
                  name: firstName,
                  getInitial: _getInitial,
                  onPressed: _onPressed,
                  isEnabled: _buttonEnabled[index],
                  isRevealed: _buttonRevealed[index],
                  voterId: widget.voterId, // voterId 전달
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialButton extends StatelessWidget {
  final int index;
  final String name;
  final String Function(String, int) getInitial;
  final ValueChanged<int> onPressed;
  final bool isEnabled;
  final bool isRevealed;
  final String voterId;

  const _InitialButton({
    Key? key,
    required this.index,
    required this.name,
    required this.getInitial,
    required this.onPressed,
    required this.isEnabled,
    required this.isRevealed,
    required this.voterId, // voterId 추가
  }) : super(key: key);

  void _revealInitial() {
    onPressed(index);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled ? _revealInitial : null,
      child: Text(
        isRevealed ? getInitial(name, index) : '?',
        style: TextStyle(fontSize: 18.sp, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? Colors.blue : Colors.grey,
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}
