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

    final uid = user.uid; // 🔸 탈퇴 전 미리 UID 저장
    final provider = await _getUserProvider(uid);
    final userEmail = user.email ?? '';
    String userPassword = '';

    try {
      if (provider == 'password') {
        userPassword = await showDialog<String>(
              context: context,
              builder: (_) => const PasswordInputDialog(),
            ) ??
            '';
        if (userPassword.isEmpty) return;
      }

      final reauthSuccess = await _reauthenticate(user, userEmail, userPassword, provider);
      if (!reauthSuccess) throw Exception("재인증 실패");

      await _deleteUserData(user, uid);
      await _signOutAllProviders();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")),
        );
      }
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

  Future<bool> _reauthenticate(User user, String email, String password, String? provider) async {
    try {
      if (provider == 'password') {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        return true;
      } else if (provider == 'google.com') {
        await GoogleSignIn().signOut(); // 🔸 기존 세션 로그아웃
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
      final isLoginSuccess = Completer<bool>();

      await NaverLoginSDK.authenticate(
        callback: OAuthLoginCallback(
          onSuccess: () {
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

  Future<void> _deleteUserData(User user, String uid) async {
    final userRef = FirebaseDatabase.instance.ref().child('users/$uid');
    await userRef.remove(); // 🔸 먼저 DB 삭제
    await user.delete(); // 🔸 재인증 후 즉시 delete
  }

  Future<void> _signOutAllProviders() async {
    await GoogleSignIn().signOut(); // 🔸 Google 로그아웃은 먼저
    await NaverLoginSDK.logout();
    await FirebaseAuth.instance.signOut();
  }
}

class PasswordInputDialog extends StatefulWidget {
  const PasswordInputDialog({super.key});

  @override
  State<PasswordInputDialog> createState() => _PasswordInputDialogState();
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
