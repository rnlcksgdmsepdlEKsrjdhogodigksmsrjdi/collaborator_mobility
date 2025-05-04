import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'user_info.dart';
import 'home_page.dart';
import 'login_page.dart';

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
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const SplashEntryScreen(),
          routes: {
            '/home': (context) => const MapWithBottomSheetPage(),
            '/login': (context) => const LoginPage(),
          },
        );
      },
    );
  }
}

class SplashEntryScreen extends StatefulWidget {
  const SplashEntryScreen({super.key});

  @override
  State<SplashEntryScreen> createState() => _SplashEntryScreenState();
}

class _SplashEntryScreenState extends State<SplashEntryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppStartupScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class AppStartupScreen extends StatelessWidget {
  const AppStartupScreen({super.key});

  Future<bool> _checkAdditionalInfoExists(String userId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId/additionalInfo')
          .get();
      return snapshot.exists &&
          snapshot.child('name').exists &&
          snapshot.child('phone').exists &&
          snapshot.child('carNumbers').exists;
    } catch (e) {
      debugPrint('❌ 추가 정보 확인 오류: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 인증 상태 로딩 중
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // 로그인 상태 확인
        final user = authSnapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        // 추가 정보 확인
        return FutureBuilder<bool>(
          future: _checkAdditionalInfoExists(user.uid),
          builder: (context, infoSnapshot) {
            if (infoSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            return infoSnapshot.data == true
                ? const MapWithBottomSheetPage()
                : UserInfoScreen(userId: user.uid);
          },
        );
      },
    );
  }
}

// ========== 공통 위젯 ==========
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(3, 3, 97, 1),
      body: SafeArea(
        child: Center(
          child: Text(
            'PIKA.EV',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Gmarket Sans TTF',
              fontSize: 50.sp,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ========== 로그아웃 핸들링 ==========
extension LogoutHandler on BuildContext {
  Future<void> signOutAndRedirect() async {
    try {
      await FirebaseAuth.instance.signOut();
      await NaverLoginSDK.logout(); // Naver 연동 로그아웃
      
      Navigator.pushAndRemoveUntil(
        this,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false, // 모든 기존 라우트 제거
      );
    } catch (e) {
      debugPrint('⚠️ 로그아웃 실패: $e');
      ScaffoldMessenger.of(this).showSnackBar(
        const SnackBar(content: Text('로그아웃에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }
}

// ========== 사용 예시 (HomePage에서 호출) ==========
// ElevatedButton(
//   onPressed: () => context.signOutAndRedirect(),
//   child: const Text('로그아웃'),
// ),