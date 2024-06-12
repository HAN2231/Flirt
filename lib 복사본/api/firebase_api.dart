import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMController {
  Future<void> sendMessage({
    required String userToken,
    required String title,
    required String body,
  }) async {
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAA2Fdl1R8:APA91bGVoB0pbDRoL3LFUT-B5ZuMXu2Z6g-ClFtVJTQ2DhO4x8a3piZp2ST9MJ2Uj1czcZWVocqmlWuiyp6VqRJz-uPeHPLYckefrcdTSaBE1sQkMuP11c07hpgF1Neuf2v7EeWzmhj9' // 자신의 서버 키로 대체하세요.
        },
        body: jsonEncode({
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'android_channel_id': 'high_importance_channel', // Android 알림 채널 ID
            'priority': 'high', // 알림 우선 순위
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
          },
          'to': userToken,
        }),
      );
      print('FCM response: ${response.body}');
    } catch (e) {
      print('Error sending FCM message: $e');
    }
  }
}
