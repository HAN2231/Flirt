import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlirterDevPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Flirt를 만든 사람들',
          style: TextStyle(color: Colors.black,fontSize:25,fontWeight: FontWeight.w700,),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요!\nLogic Legend팀 입니다.',
              style: TextStyle(fontSize: 15.0, color: Colors.grey[700]),
            ),
            Divider(
              thickness: 2,
              height: 20,
              color: Colors.grey[200],
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 20, 15, 20),
              child: const Text(
                'Logic Legend',
                style: TextStyle(
                  fontSize: 25.0,
                  color: Colors.black,
                    fontWeight: FontWeight.w700,
                ),
              ),
            ),
            buildTeamMember(
              imagePath: 'assets/KANG.jpg',
              name: '임강현 #컴공 #17',
              role: 'FS Developer',
            ),
            SizedBox(height: 20),
            buildTeamMember(
              imagePath: 'assets/SENG.jpg',
              name: '홍승관 #컴공 #17',
              role: 'FS Developer',
            ),
            SizedBox(height: 20),
            buildTeamMember(
              imagePath: 'assets/HAN.jpg',
              name: '한형규 #컴공 #21',
              role: 'FS Developer',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTeamMember({
    required String imagePath,
    required String name,
    required String role,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          child: Image.asset(
            imagePath,
            width: 80,
            height: 80,
          ),
        ),
        SizedBox(width: 20),
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
