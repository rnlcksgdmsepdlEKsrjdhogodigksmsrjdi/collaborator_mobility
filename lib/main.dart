import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    clientId: 'IGdjiddEnJx86dWfnGW0',
    clientSecret: 'dX02epXz4L',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil 초기화를 MaterialApp 상위에 배치
    return ScreenUtilInit(
      designSize: const Size(390, 844), // 디자인 기기 크기 (iPhone 13 기준)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PIKA.EV',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: child,
        );
      },
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(); // 로딩 화면으로 변경
          } else if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil 사용을 위해 context 필요
    return Scaffold(
      body: Container(
        width: 390.w, // .w로 너비 지정
        height: 844.h, // .h로 높이 지정
        decoration: BoxDecoration(
          color: const Color.fromRGBO(3, 3, 97, 1),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 393.h, // .h로 위치 지정
              left: 84.w, // .w로 위치 지정
              child: Text(
                'PIKA.EV',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 1),
                  fontFamily: 'Gmarket Sans TTF',
                  fontSize: 50.sp, // .sp로 폰트 크기 지정
                  letterSpacing: 0,
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