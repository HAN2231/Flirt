import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 처리방침',style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25)),
        surfaceTintColor: Colors.transparent,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '본 개인정보 처리방침은 당사의 서비스 및 웹사이트(이하 "서비스"로 통칭함)에서 개인정보를 수집, 사용, 공유 및 보호하는 방법에 대한 정책을 설명합니다.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '수집하는 개인정보의 종류',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '당사는 서비스 이용 등록 및 제품 구매, 고객 지원 요청 등을 위해 다음과 같은 개인정보를 수집할 수 있습니다:\n- 이름\n- 이메일 주소\n- 학과\n- 나이\n- 기타 관련 정보',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '개인정보의 사용',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '당사는 수집된 개인정보를 다음과 같은 목적으로 사용할 수 있습니다:\n- 서비스 제공 및 관리\n- 이용자 식별 및 인증\n- 고객 지원 제공\n- 상품 또는 서비스 개선 및 마케팅 활동\n- 법적 요구에 응하기',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '개인정보의 보호',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '당사는 적절한 보안 조치를 통해 개인정보를 보호하고 유출, 변조, 손실 또는 불법적인 액세스로부터 보호합니다.\n개인정보는 암호화된 통신 채널을 통해 전송되며 안전한 서버에 저장됩니다.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '정보 공유',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '당사는 사용자의 동의 없이 개인정보를 제3자와 공유하지 않습니다. 그러나 다음의 경우에는 예외적으로 개인정보를 공유할 수 있습니다:\n- 법적 요구가 있는 경우\n- 서비스 제공을 위해 협력사와 개인정보를 공유해야 하는 경우',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '사용자의 권리',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '사용자는 본인의 개인정보에 대한 열람, 수정, 삭제 요청을 할 수 있습니다. 이에 대한 절차는 당사의 고객 지원팀을 통해 안내 받을 수 있습니다.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '포인트 및 추적 기술',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '당사는 쿠키 및 웹 비콘과 같은 추적 기술을 사용하여 서비스 이용 통계를 수집할 수 있습니다. 이 정보는 개인을 식별할 수 없는 형태로 사용되며 서비스 개선 및 마케팅에 활용됩니다.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            Text(
              '변경 사항',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
            ),
            Text(
              '본 개인정보 처리방침이 변경될 경우, 변경 사항을 서비스 내에 공지하고 본 페이지에 업데이트합니다. 변경 사항을 확인하려면 정기적으로 이 페이지를 방문하시기 바랍니다.',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}