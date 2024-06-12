import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logintest/profile/setting/setting_page.dart';
import 'package:logintest/vote/postvote_page.dart';
import 'welcomescreen/welcome_screen_page.dart';
import 'auth/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/menus/cardroom_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  try {
    await Firebase.initializeApp(
      options: Platform.isAndroid
          ? const FirebaseOptions(
        apiKey: 'AIzaSyBayTSx3oKg_hMNslP0Go4awUc-txZDHfI',
        appId: '1:929179227423:android:c6472589c65e32ad8c0c2a',
        messagingSenderId: '929179227423',
        projectId: 'seng-c94ca',
      )
          : const FirebaseOptions(
        apiKey: 'AIzaSyD6X-Qj4B6v_L5z9vA-oKUy90d-urjMzWnE',
        appId: '1:929179227423:ios:88aaff582a51d8ef8c0c2a',
        messagingSenderId: '929179227423',
        projectId: 'seng-c94ca',
        iosBundleId: 'com.example.app', // iOS 번들 ID 추가
      ),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final initialRoute = await getInitialRoute();

    runApp(MyApp(initialRoute: initialRoute));
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // If the app is already initialized, just run the app
      final initialRoute = await getInitialRoute();
      runApp(MyApp(initialRoute: initialRoute));
    } else {
      rethrow;
    }
  }
}

Future<String> getInitialRoute() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasSeenAppInfo = prefs.getBool('hasSeenAppInfo') ?? false;
  return hasSeenAppInfo ? '/auth' : '/appinfo';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 하단 바 배경색을 투명하게 설정
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 상태 바 투명색
      systemNavigationBarColor: Colors.transparent, // 하단 바 투명색
    ));
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      //initialRoute: '/auth', // 로그인 페이지로 이동
      onGenerateRoute: (settings) {
        if (settings.name == '/postvote') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return PostvotePage(
                remainingQuestions: args['remainingQuestions'],
                earnedPoints: args['earnedPoints'],
              );
            },
          );
        }
        // Define other routes here...
        return null;
      },
      routes: {
        '/appinfo': (context) => WelcomeScreenPage(),
        '/auth': (context) => AuthPage(),
        '/cardroom': (context) => CardRoomPage(),
        '/home': (context) => HomePage(),
        '/setting': (context) => SettingPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    // 앱이 포그라운드에 있을 때 수신된 메시지를 처리하는 부분입니다.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
              'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle the notification when the app is opened from a terminated state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Demo Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have pushed the button this many times:'),
          ],
        ),
      ),
    );
  }
}
