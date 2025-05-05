import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:http/http.dart' as http;

class UserService {
  Future<void> deleteUserAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 데이터베이스에서 provider 정보 가져오기
    final provider = await _getUserProvider(user.uid);
    final userEmail = user.email ?? '';
    String userPassword = '';

    try {
      if (provider == 'password') {
        // 이메일 로그인 사용자만 비밀번호 입력 다이얼로그 표시
        userPassword = await showDialog<String>(
          context: context,
          builder: (_) => PasswordInputDialog(),
        ) ?? '';
        
        if (userPassword.isEmpty) return;
      }
      
      await _handleDelete(context, user, userEmail, userPassword, provider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원 탈퇴 실패: ${e.toString()}")),
        );
      }
    }
  }

  Future<String?> _getUserProvider(String uid) async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users/$uid/basicInfo/provider')
        .get();
    return snapshot.value?.toString();
  }

  Future<void> _handleDelete(BuildContext context, User user, String email, String password, String? provider) async {
    final success = await _reauthenticate(user, email, password, provider);
    if (!success) throw Exception("재인증 실패");

    await _deleteUserDataAndLogout(user);

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")),
      );
    }
  }

  Future<bool> _reauthenticate(User user, String email, String password, String? provider) async {
    try {
      if (provider == 'password') {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        return true;
      } else if (provider == 'google.com') {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return false;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      } else if (provider == 'naver') {
        return await _reauthenticateWithNaver();
      }
      return false;
    } catch (e) {
      debugPrint("재인증 실패: $e");
      return false;
    }
  }

  Future<bool> _reauthenticateWithNaver() async {
    try {
      // 네이버 로그인 성공 여부 확인
      final isLoginSuccess = Completer<bool>();
      
      await NaverLoginSDK.authenticate(
        callback: OAuthLoginCallback(
          onSuccess: () async {
            isLoginSuccess.complete(true);
          },
          onFailure: (_, msg) {
            isLoginSuccess.completeError(Exception("네이버 로그인 실패: $msg"));
          },
          onError: (_, msg) {
            isLoginSuccess.completeError(Exception("네이버 로그인 에러: $msg"));
          },
        ),
      );

      return await isLoginSuccess.future;
    } catch (e) {
      debugPrint("네이버 재인증 실패: $e");
      return false;
    }
  }

  Future<void> _deleteUserDataAndLogout(User user) async {
    // 사용자 데이터 삭제
    final userRef = FirebaseDatabase.instance.ref().child('users/${user.uid}');
    await userRef.remove();
    
    // Firebase 계정 삭제
    await user.delete();
    
    // 모든 로그아웃 처리
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await NaverLoginSDK.logout();
  }
}

class PasswordInputDialog extends StatefulWidget {
  const PasswordInputDialog({super.key});

  @override
  _PasswordInputDialogState createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<PasswordInputDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("비밀번호 입력"),
      content: TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: '비밀번호'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _passwordController.text),
          child: const Text("확인"),
        ),
      ],
    );
  }
}