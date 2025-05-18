import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:naver_login_sdk/naver_login_sdk.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> reauthenticateUser(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar(context, '로그인 정보가 없습니다.');
      return false;
    }

    try {
      final provider = await _getUserProvider(user.uid);
      if (provider == null) {
        _showSnackBar(context, '인증 제공자 정보를 찾을 수 없습니다.');
        return false;
      }

      switch (provider) {
        case 'google.com':
          return await _handleGoogleReauth();
        case 'naver':
          return await _reauthenticateWithNaver(context, user);
        case 'email':
          return await _reauthenticateWithEmail(context, user);
        default:
          return await _reauthenticateWithEmail(context, user);
      }
    } catch (e) {
      _showSnackBar(context, '재인증 실패: ${e.toString()}');
      return false;
    }
  }

  Future<String?> _getUserProvider(String uid) async {
    final snapshot = await _database.ref().child('users/$uid/basicInfo/provider').get();
    return snapshot.value?.toString();
  }

  // Google 재인증 처리 (간소화 버전)
  Future<bool> _handleGoogleReauth() async {
    try {
      // 기존에 로그인된 계정이 있는지 확인
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signInSilently();
        return true;
      }
      
      // 없으면 새로 로그인 시도
      final googleUser = await _googleSignIn.signIn();
      return googleUser != null;
    } catch (e) {
      print('Google 재인증 오류: $e');
      return false;
    }
  }

  // Naver 재인증 처리 (간소화 버전)
  Future<bool> _reauthenticateWithNaver(BuildContext context, User user) async {
  try {
    // 1. 네이버 인증 시도
    final authResult = await _authenticateWithNaver();
    if (!authResult.success) {
      _showSnackBar(context, '네이버 재인증 실패: ${authResult.message}');
      return false;
    }

    // 2. 프로필 정보 가져오기
    final profileResult = await _getNaverProfile();
    if (!profileResult.success) {
      _showSnackBar(context, '프로필 정보 가져오기 실패: ${profileResult.message}');
      return false;
    }

    final profile = profileResult.profile!;
    final naverId = profile.id ?? 'default_naver_id';
    final email = profile.email ?? '$naverId@naver.com';
    final accessToken = await NaverLoginSDK.getAccessToken();

    // 3. Firebase 커스텀 토큰 요청
    final customToken = await _getFirebaseCustomToken(
      accessToken: accessToken,
      naverId: naverId,
      email: email,
    );

    // 4. Firebase 재인증
    await _auth.signInWithCustomToken(customToken);
    return true;
  } catch (e) {
    _showSnackBar(context, '네이버 재인증 중 오류 발생: ${e.toString()}');
    return false;
  }
}

// 네이버 인증 처리 (기존 로그인 방식과 동일)
Future<({bool success, String? message})> _authenticateWithNaver() async {
  try {
    final completer = Completer<({bool success, String? message})>();
    
    await NaverLoginSDK.authenticate(
      callback: OAuthLoginCallback(
        onSuccess: () => completer.complete((success: true, message: null)),
        onFailure: (httpStatus, message) => 
          completer.complete((success: false, message: '상태코드: $httpStatus | 메시지: $message')),
        onError: (errorCode, message) => 
          completer.complete((success: false, message: '코드: $errorCode | 메시지: $message')),
      ),
    );
    
    return await completer.future;
  } catch (e) {
    return (success: false, message: '예외 발생: ${e.toString()}');
  }
}

// 네이버 프로필 정보 가져오기 (기존 로그인 방식과 동일)
Future<({bool success, NaverLoginProfile? profile, String? message})> _getNaverProfile() async {
  try {
    final completer = Completer<({bool success, NaverLoginProfile? profile, String? message})>();
    
    await NaverLoginSDK.profile(
      callback: ProfileCallback(
        onSuccess: (resultCode, message, response) {
          final profile = NaverLoginProfile.fromJson(response: response);
          completer.complete((success: true, profile: profile, message: null));
        },
        onFailure: (httpStatus, message) => 
          completer.complete((success: false, profile: null, message: '상태코드: $httpStatus | 메시지: $message')),
        onError: (errorCode, message) => 
          completer.complete((success: false, profile: null, message: '코드: $errorCode | 메시지: $message')),
      ),
    );
    
    return await completer.future;
  } catch (e) {
    return (success: false, profile: null, message: '예외 발생: ${e.toString()}');
  }
}

// Firebase 커스텀 토큰 요청 (기존 로그인 방식과 동일)
Future<String> _getFirebaseCustomToken({
  required String accessToken,
  required String naverId,
  required String email,
}) async {
  const url = "https://naverlogin-ov5rbv4c3q-du.a.run.app";
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessToken': accessToken,
        'naverId': naverId,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final token = responseData['token'] ?? responseData['customToken'];
      
      if (token == null) {
        throw Exception('토큰 값이 서버 응답에 존재하지 않습니다: ${response.body}');
      }
      
      return token.toString();
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    debugPrint('🔥 커스텀 토큰 요청 실패: $e');
    throw Exception('토큰 발급 실패: $e');
  }
}

  // 이메일 로그인 (기존 방식 유지)
  Future<bool> _reauthenticateWithEmail(BuildContext context, User user) async {
  final email = user.email;
  if (email == null) {
    if (context.mounted) {
      _showSnackBar(context, '이메일 정보를 찾을 수 없습니다.');
    }
    return false;
  }

  final passwordController = TextEditingController();
  bool success = false;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: 270.09.w,
        height: 242.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(
            color: const Color.fromRGBO(217, 217, 217, 1),
            width: 1,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 57.h,
              left: 101.w,
              child: Text(
                '비밀번호',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 87.h,
              left: 22.w,
              child: Container(
                width: 227.w,
                height: 48.h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(  
                      fontFamily: 'Paperlogy',
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 167.h,
              left: 78.w,
              child: GestureDetector(
                onTap: () async {
                  final password = passwordController.text.trim();
                  if (password.isEmpty) return;

                  try {
                    final credential = EmailAuthProvider.credential(
                      email: email,
                      password: password,
                    );
                    await user.reauthenticateWithCredential(credential);
                    success = true;
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showSnackBar(context, '인증 성공');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showSnackBar(context, '비밀번호가 일치하지 않습니다.');
                    }
                  }
                },
                child: Container(
                  width: 113.w,
                  height: 43.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromRGBO(3, 3, 97, 1),
                  ),
                  child: Center(
                    child: Text(
                      '수정하기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Paperlogy',
                        fontSize: 22.sp,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.normal,
                        height: 0.91,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return success;
}

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}