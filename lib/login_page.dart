import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobility/sign_in_page.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;
import 'home_page.dart';
import 'user_info.dart'; // 추가 정보 입력 화면 임포트 확인!

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 모든 로그인 공통: 추가 정보 확인 후 라우팅
  Future<void> _handleLoginSuccess(User user) async {
    final requiresInfo = await _requiresAdditionalInfo(user.uid);
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => requiresInfo
            ? UserInfoScreen(userId: user.uid)
            : const MapWithBottomSheetPage(),
      ),
    );
  }

  // 추가 정보 필요 여부 확인
  Future<bool> _requiresAdditionalInfo(String uid) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$uid/additionalInfo')
          .get();

      return !(snapshot.exists &&
          snapshot.child('name').exists &&
          snapshot.child('phone').exists &&
          snapshot.child('carNumbers').exists);
    } catch (e) {
      debugPrint('추가 정보 확인 오류: $e');
      return true; // 오류 시 추가 정보 입력 화면으로
    }
  }

  // 사용자 데이터 저장
  Future<void> saveUserData(User user, {String provider = ''}) async {
    final userRef = FirebaseDatabase.instance.ref('users/${user.uid}/basicInfo');
    await userRef.update({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'provider': provider.isNotEmpty ? provider : user.providerData.first.providerId,
      'lastLogin': DateTime.now().toIso8601String()
    });
  }

  // 에러 표시
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // 이메일 로그인
  Future<void> signInWithEmail() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!credential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _showError("이메일 인증을 완료해주세요.");
        return;
      }

      await saveUserData(credential.user!);
      await _handleLoginSuccess(credential.user!);
    } catch (e) {
      _showError("로그인 실패: ${e.toString()}");
    }
  }

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await saveUserData(userCredential.user!, provider: 'google.com');
      await _handleLoginSuccess(userCredential.user!);
    } catch (e) {
      _showError("구글 로그인 실패: ${e.toString()}");
    }
  }

  // 네이버 로그인
  Future<void> signInWithNaver() async {
    try {
      await NaverLoginSDK.authenticate(
        callback: OAuthLoginCallback(
          onSuccess: () async {
            final accessToken = await NaverLoginSDK.getAccessToken();
            final profile = await _getNaverProfile();
            final customToken = await _getFirebaseCustomToken(
              accessToken: accessToken,
              naverId: profile.id!,
              email: profile.email ?? '${profile.id}@naver.com',
            );

            final userCredential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
            await saveUserData(userCredential.user!, provider: 'naver');
            await _handleLoginSuccess(userCredential.user!);
          },
          onFailure: (_, msg) => _showError("네이버 로그인 실패: $msg"),
          onError: (_, msg) => _showError("네이버 로그인 오류: $msg"),
        ),
      );
    } catch (e) {
      _showError("네이버 로그인 중 예외: ${e.toString()}");
    }
  }

  // 네이버 프로필 조회
  Future<NaverLoginProfile> _getNaverProfile() async {
    final completer = Completer<NaverLoginProfile>();
    NaverLoginSDK.profile(
      callback: ProfileCallback(
        onSuccess: (_, __, res) => completer.complete(NaverLoginProfile.fromJson(response: res)),
        onFailure: (_, msg) => completer.completeError(Exception(msg)),
        onError: (_, msg) => completer.completeError(Exception(msg)),
      ),
    );
    return completer.future;
  }

  // Firebase 커스텀 토큰 요청
  Future<String> _getFirebaseCustomToken({
    required String accessToken,
    required String naverId,
    required String email,
  }) async {
    const url = "https://naverlogin-ov5rbv4c3q-du.a.run.app";
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken, 'naverId': naverId, 'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'] as String;
    } else {
      throw Exception('토큰 발급 실패: ${response.body}');
    }
  }

   // 디자인 파트
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 390.w,
        height: 844.h,
        color: const Color.fromRGBO(255, 255, 255, 1),
        child: Stack(
          children: [
            Positioned(
              top: 47.h,
              left: 160.w,
              child: Text(
                'LOGIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Gmarket Sans TTF',
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 101.h,
              left: 20.w,
              child: Container(
                width: 350.w,
                height: 43.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: emailController,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Paperlogy',
                      fontSize: 20.sp,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '아이디',
                      hintStyle: TextStyle(
                        color: const Color.fromRGBO(217, 217, 217, 1),
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.normal,
                        height: 1,
                      ),
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 152.h,
              left: 20.w,
              child: Container(
                width: 350.w,
                height: 43.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    obscuringCharacter: '*',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Paperlogy',
                      fontSize: 20.sp,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '비밀번호',
                      hintStyle: TextStyle(
                        color: const Color.fromRGBO(217, 217, 217, 1),
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.normal,
                        height: 1,
                      ),
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 216.h,
              left: 20.w,
              child: GestureDetector(
                onTap: signInWithEmail,
                child: Container(
                  width: 350.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(3, 3, 97, 1),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: Center(
                    child: Text(
                      '로그인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Paperlogy',
                        fontSize: 15.sp,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.normal,
                        height: 1,
                      ),
                    )
                  ),
                ),
              ),
            ),
            Positioned(
              top: 347.h,
              left: 122.w,
              child: Text(
                'SNS계정으로 로그인하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Paperlogy',
                  fontSize: 15.sp,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1.33,
                ),
              ),
            ),
            Positioned(
              top: 381.h,
              left: 131.w,
              child: GestureDetector(
                onTap: signInWithNaver,
                child: Container(
                  width: 54.w,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(87, 176, 75, 1),
                    borderRadius: BorderRadius.all(Radius.circular(54.r)),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/vector.svg',
                      width: 24.w,
                      height: 24.h,
                      semanticsLabel: 'vector',
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 506.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                child: Container(
                  width: 350.w,
                  height: 41.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.r),
                    border: Border.all(
                      color: const Color.fromRGBO(17, 17, 17, 1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '회원가입',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromRGBO(17, 17, 17, 1),
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.normal,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 381.h,
              left: 205.w,
              child: GestureDetector(
                onTap: signInWithGoogle,
                child: Container(
                  width: 54.w,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(54.r),
                    border : Border.all(
                    color: Color.fromRGBO(217, 217, 217, 1),
                    width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 14.h,
                        left: 14.w,
                        child: SizedBox(
                          width: 25.w,
                          height: 27.h,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 11.h,
                                left: 12.w,
                                child: SvgPicture.asset(
                                  'assets/images/vector4.svg',
                                  semanticsLabel: 'vector4',
                                ),
                              ),
                              Positioned(
                                top: 16.h,
                                left: 1.w,
                                child: SvgPicture.asset(
                                  'assets/images/vector3.svg',
                                  semanticsLabel: 'vector3',
                                ),
                              ),
                              Positioned(
                                top: 7.h,
                                left: 0.w,
                                child: SvgPicture.asset(
                                  'assets/images/vector2.svg',
                                  semanticsLabel: 'vector2',
                                ),
                              ),
                              Positioned(
                                top: 0.h,
                                left: 1.w,
                                child: SvgPicture.asset(
                                  'assets/images/vector1.svg',
                                  semanticsLabel: 'vector1',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 279.h,
              left: 99.w,
              child: Text(
                '아이디 찾기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromRGBO(217, 217, 217, 1),
                  fontFamily: 'Paperlogy',
                  fontSize: 14.sp,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1.43,
                ),
              ),
            ),
            Positioned(
              top: 281.h,
              left: 195.w,
              child: Transform.rotate(
                angle: -90 * (math.pi / 180),
                child: Divider(
                  color: const Color.fromRGBO(217, 217, 217, 1),
                  thickness: 1,
                  height: 10.h,
                ),
              ),
            ),
            Positioned(
              top: 279.h,
              left: 228.w,
              child: Text(
                '비밀번호 찾기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromRGBO(217, 217, 217, 1),
                  fontFamily: 'Paperlogy',
                  fontSize: 14.sp,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1.43,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}