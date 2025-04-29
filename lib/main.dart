import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NaverLoginSDK.initialize(
    clientId: 'IGdjiddEnJx86dWfnGW0',
    clientSecret: 'dX02epXz4L',
  );
  
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit( // ✅ ScreenUtilInit은 MyApp 내부에서
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const AppStartupScreen(), // Splash + 인증 체크를 담당하는 새 위젯
        );
      },
    );
  }
}

// 수정된 AppStartupScreen 코드
class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  late final Future<bool> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<bool> _initializeApp() async {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase 초기화 성공');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase 초기화 실패: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // 1. 초기화 중에는 스플래시 화면 유지
        if (!snapshot.hasData) {
          return const SplashScreen();
        }

        // 2. Firebase 초기화 실패 시 에러 화면
        if (snapshot.data == false) {
          return const Center(child: Text('Firebase 연결 실패'));
        }

        // 3. 인증 상태 확인
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            debugPrint('🔑 인증 상태: ${authSnapshot.connectionState}');
            debugPrint('👤 사용자 UID: ${authSnapshot.data?.uid ?? "null"}');

            if (authSnapshot.connectionState == ConnectionState.active) {
              return authSnapshot.hasData ? const HomePage() : const LoginPage();
            }
            return const SplashScreen(); // 인증 체크 중
          },
        );
      },
    );
  }
}



class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF030361), // RGBO(3, 3, 97)
      child: Center(
        child: Text(
          'PIKA.EV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 50.sp,
            fontFamily: 'Gmarket Sans TTF',
          ),
        ),
      ),
    );
  }
}