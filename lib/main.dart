import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  
  NaverLoginSDK.initialize(
    clientId: 'IGdjiddEnJx86dWfnGW0',        // 네이버 개발자 센터에서 받은 clientId 
    clientSecret: 'dX02epXz4L',// 네이버 개발자 센터에서 받은 clientSecret
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
