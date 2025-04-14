import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobility/sign_in_page.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 이메일 / 패스워드 입력 컨트롤러 관련 
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 에러 메세지 함수
  void _showError(String message) {
    if (!mounted) return; // 위젯이 unmount된 경우 방지
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
    print('에러 발생: $message'); // 콘솔 로깅
  }
  
  // 이메일/비밀번호 직접 설정해서 가입하는 함수
  Future<void> signInWithEmail() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!credential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이메일 인증을 완료해주세요.")),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 성공!")),
      );
    } catch (e) {
      _showError("로그인 실패: ${e.toString()}");
    }
  }

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
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
          // 1. 프로필 조회
          await NaverLoginSDK.profile(
            callback: ProfileCallback(
              onSuccess: (resultCode, message, response) async {
                print('''
                  🔵 프로필 조회 성공
                  - resultCode: $resultCode
                  - message: $message
                  - rawResponse: $response
                ''');

                // 2. 프로필 파싱 (NaverLoginProfile.fromJson 사용)
                final profile = NaverLoginProfile.fromJson(response: response);
                final naverId = profile.id ?? 'default_naver_id';
                final email = profile.email ?? '$naverId@naver.com';

                // 3. Firebase 연동 - 토큰화
                final accessToken = await NaverLoginSDK.getAccessToken(); // String 직접 반환
                final customToken = await _getFirebaseCustomToken(
                  accessToken: accessToken, 
                  naverId: naverId,
                  email: email,
                );
                await FirebaseAuth.instance.signInWithCustomToken(customToken); // Firebase 인증 관련된 함수로 토큰받아 진행

                // 4. 성공 알림
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("네이버 로그인 성공!")),
                );

                // 5. 프로필 상세 출력 (디버깅) - 확인용
                print('''
                  🟢 최종 파싱된 프로필
                  - ID: ${profile.id}
                  - Email: ${profile.email}
                ''');
              },
              onFailure: (httpStatus, message) {
                throw Exception("프로필 조회 실패 | 상태코드: $httpStatus | 메시지: $message");
              },
              onError: (errorCode, message) {
                throw Exception("프로필 조회 오류 | 코드: $errorCode | 메시지: $message");
              },
            ),
          );
        },
        onFailure: (httpStatus, message) {
          _showError("네이버 로그인 실패 | 상태코드: $httpStatus | 메시지: $message");
        },
        onError: (errorCode, message) {
          _showError("네이버 로그인 오류 | 코드: $errorCode | 메시지: $message");
        },
      ),
    );
  } catch (e) {
    _showError("네이버 로그인 중 예외 발생: ${e.toString()}");
  }
}

  //  Firebase 커스텀 토큰 요청 - 네이버 API -> Firebase로 값을 보냄
  Future<String> _getFirebaseCustomToken({
  required String accessToken,
  required String naverId,
  required String email,
}) async {
  const functionUrl = "https://naverlogin-ov5rbv4c3q-du.a.run.app"; // 네이버 API 관련 url - 상수

  try {
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {'Content-Type': 'application/json'}, // json으로 보냄
      body: jsonEncode({
        'accessToken': accessToken,
        'naverId': naverId,
        'email': email,
      }),
    );

    //  응답 검증 강화
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final token = responseData['token'] ?? responseData['customToken'];
      if (token != null && token is String) {
        return token;
      } else {
        throw Exception('유효하지 않은 토큰 형식: ${response.body}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('🔥 커스텀 토큰 요청 실패: $e');
    throw Exception('토큰 발급 실패: $e'); 
  }
}

// 앱화면 구조
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "이메일")),
              const SizedBox(height: 10),
              TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "비밀번호")),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: signInWithEmail, child: const Text("로그인")),

              const SizedBox(height: 20),
              const Divider(),
              const Text("또는"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: signInWithGoogle,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Google로 로그인", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: signInWithNaver,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Naver로 로그인", style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                child: const Text("이메일로 회원가입하기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
