import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'user_info.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'my_page_screen.dart';
import 'fcm_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NaverLoginSDK.initialize(
    clientId: 'IGdjiddEnJx86dWfnGW0',
    clientSecret: 'dX02epXz4L',
  );
  
    runApp(
      ProviderScope(child: MyApp())
    );
  
  
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
            '/mypage': (context) {
              final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
              return MyPageScreen(userId: userId);
            },

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

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  final FCMHandler _fcmHandler = FCMHandler(); // FCM 핸들러 선언

  @override
  void initState() {
    super.initState();

    // FCM 초기화 및 메시지 처리 등록
    _fcmHandler.initializeFCM(context);
  }

  // 추가 정보 필요 여부 확인
  Future<bool> _requiresAdditionalInfo(String userId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId/additionalInfo')
          .get();

      final hasAdditionalInfo = snapshot.exists &&
          snapshot.child('name').exists &&
          snapshot.child('phone').exists &&
          snapshot.child('carNumbers').exists;

      return !hasAdditionalInfo;
    } catch (e) {
      debugPrint('❌ 추가 정보 확인 오류: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<bool>(
          future: _requiresAdditionalInfo(user.uid),
          builder: (context, infoSnapshot) {
            if (infoSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            return infoSnapshot.data == true
                ? UserInfoScreen(userId: user.uid)
                : const MapWithBottomSheetPage();
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