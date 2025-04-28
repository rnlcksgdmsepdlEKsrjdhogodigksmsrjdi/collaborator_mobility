import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화

  // 네이버 로그인 SDK 초기화
  NaverLoginSDK.initialize(
    clientId: 'IGdjiddEnJx86dWfnGW0',  // 네이버 개발자 센터에서 받은 clientId
    clientSecret: 'dX02epXz4L',        // 네이버 개발자 센터에서 받은 clientSecret
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // 로그인 상태 체크
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const HomePage(); // 로그인 되어있으면 홈으로
          } else {
            return const LoginPage(); // 로그인 안 되어있으면 로그인 페이지
          }
        },
      ),
    );
  }
}

class Iphone13141Widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 로딩화면
    return Scaffold(
      body: Container(
        width: 390,
        height: 844,
        decoration: BoxDecoration(
          color: Color.fromRGBO(3, 3, 97, 1), // 앱 배경 색상
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 393,
              left: 84,
              child: Text(
                'PIKA.EV', // 앱 이름
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 1), // 텍스트 색상
                  fontFamily: 'Gmarket Sans TTF', // 텍스트 폰트
                  fontSize: 50, // 폰트 크기
                  letterSpacing: 0, // 문자 간격
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
