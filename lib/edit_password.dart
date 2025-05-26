import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _changePassword() async {
    final user = _auth.currentUser;

    if (user == null || user.providerData.first.providerId != 'password') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '이메일 가입 사용자만 비밀번호를 수정할 수 있습니다.',
            ),
        duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '비밀번호가 일치하지 않습니다.',
            ),
        duration: const Duration(seconds: 2),
        ),
      );
      
      return;
    }

    try {
      await user.updatePassword(newPassword);
      Navigator.pushReplacementNamed(context, '/home');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '비밀번호가 성공적으로 변경되었습니다.',
            ),
        duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '비밀번호 변경 실패: ${e.toString()}',
            ),
        duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 390,
        height: 844,
        decoration: BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            // 뒤로가기 아이콘 배경 포함
            Positioned(
              top: 45,
              left: 20,
              child: Container(
                width: 28,
                height: 28,
                color: Colors.white,
                child: SvgPicture.asset(
                  'assets/images/icon.svg',
                  semanticsLabel: 'icon',
                ),
              ),
            ),

            // 타이틀
            Positioned(
              top: 49,
              left: 141,
              child: Text(
                '비밀번호 수정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 20,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                  color: Colors.black,
                ),
              ),
            ),

            // 비밀번호 라벨
            Positioned(
              top: 112,
              left: 20,
              child: Text(
                '비밀번호',
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 23,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 0.87,
                  color: Color.fromRGBO(217, 217, 217, 1),
                ),
              ),
            ),

            // 비밀번호 입력 필드
            Positioned(
              top: 140,
              left: 20,
              right: 20,
              child: TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '새 비밀번호를 입력하세요',
                  hintStyle: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 20.sp,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.normal,
                    height: 1,
                    color: Color.fromRGBO(217, 217, 217, 1),
                ),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF030361)),
                    ),
                ),
              ),
            ),

            // 비밀번호 확인 라벨
            Positioned(
              top: 210,
              left: 20,
              child: Text(
                '비밀번호 확인',
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 23,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                  color: Color.fromRGBO(217, 217, 217, 1),
                ),
              ),
            ),

            // 비밀번호 확인 입력 필드
            Positioned(
              top: 240,
              left: 20,
              right: 20,
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '다시 입력하세요',
                  hintStyle: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 20.sp,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.normal,
                    height: 1,
                    color: Color.fromRGBO(217, 217, 217, 1),
                ),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF030361)),
                    ),
                ),
              ),
            ),

            
            Positioned(
              top: 738,
              left: 20,
              child: GestureDetector(
                onTap: () => _changePassword(),
                child: Container(
                  width: 350.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Color(0xFF030361),
                    borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
