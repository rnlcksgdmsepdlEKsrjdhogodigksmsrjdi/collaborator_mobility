// 게정 탈퇴 관련 코드입니다.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

class UserService {
  Future<void> deleteUserAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // DB에서 provider, email 가져오기 
    final provider = await _getUserProvider(user.uid);
    final userEmail = user.email ?? '';
    String userPassword = ''; // passwd는 확인용으로 존재 

    try {
      if (provider == 'password') {
        // 이메일 로그인 사용자만 비밀번호 입력 다이얼로그 표시
        userPassword = await showDialog<String>(
          context: context,
          builder: (_) => PasswordInputDialog(),
        ) ?? '';
        
        if (userPassword.isEmpty) return;
      }
      
      await _handleDelete(context, user, userEmail, userPassword, provider); // 탈퇴
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원 탈퇴 실패: ${e.toString()}")),
        );
      }
    }
  }

  // uid provider 제공 
  // 원래는 auth에서 provider를 기본으로 제공해주는데 네이버 로그인 같은 경우는 auth 주관이 아니라서 db에 저장함
  // 이를 불러옴
  Future<String?> _getUserProvider(String uid) async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users/$uid/basicInfo/provider')
        .get();
    return snapshot.value?.toString();
  }

  // 탈퇴 함수
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

  // 재인증 함수
  Future<bool> _reauthenticate(User user, String email, String password, String? provider) async {
    // 이메일 유저만 passwd 입력 후 진행하게 함 
    try {
      if (provider == 'password') {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        return true;
      } else if (provider == 'google.com') {
        final googleUser = await GoogleSignIn().signIn(); // 다시 로그인하는 과정을 통해서 재인증 
        if (googleUser == null) return false;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      } else if (provider == 'naver') {
        return await _reauthenticateWithNaver(); // 네이버는 따로 처리하는 함수 진행 
      }
      return false;
    } catch (e) {
      debugPrint("재인증 실패: $e");
      return false;
    }
  }
  // 네이버 재인증 - 다시 로그인 해서 되는지 확인
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
    // DB에 저장된 유저 내용 삭제 
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

// 비밀번호 입력
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