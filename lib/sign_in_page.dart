import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user?.sendEmailVerification();
      await auth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일 인증 링크를 보냈습니다. 인증 후 로그인해주세요.")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = '회원가입 실패';
      if (e.code == 'weak-password') {
        message = '비밀번호가 너무 약합니다';
      } else if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 이메일입니다';
      } else if (e.code == 'invalid-email') {
        message = '유효하지 않은 이메일 형식입니다';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return Stack(
            children: <Widget>[
              // 앱 로고
              Positioned(
                top: 106.h,
                left: 130.w,
                child: Text(
                  'PIKA.EV',
                  style: TextStyle(
                    color: const Color.fromRGBO(17, 17, 17, 1),
                    fontFamily: 'Inter',
                    fontSize: 30.sp,
                    fontWeight: FontWeight.normal,
                    height: 1,
                  ),
                ),
              ),

              // 이메일 입력 필드
              Positioned(
                top: 161.h,
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                        hintText: '이메일',
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

              // 비밀번호 입력 필드 (* 마스킹 적용)
              Positioned(
                top: 213.h,
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
                      controller: _passwordController,
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

              // 비밀번호 확인 입력 필드 (* 마스킹 적용)
              Positioned(
                top: 264.h,
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
                      controller: _confirmPasswordController,
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
                        hintText: '비밀번호 확인',
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

              // 가입하기 버튼
              Positioned(
                top: 720.h,
                left: 20.w,
                child: GestureDetector(
                  onTap: _isLoading ? null : _signUp,
                  child: Container(
                    width: 350.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _isLoading 
                          ? const Color.fromRGBO(217, 217, 217, 1)
                          : const Color.fromRGBO(3, 3, 97, 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              '가입하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Paperlogy',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.normal,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              
              // 뒤로 가기 아이콘
              Positioned(
                top: 45.h,
                left: 20.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    width: 28.w,
                    height: 28.h,
                    child: SvgPicture.asset(
                      'assets/images/icon.svg',
                      semanticsLabel: 'icon',
                    ),
                  ),
                ),
              ),

              // 화면 제목 (회원가입)
              Positioned(
                top: 49.h,
                left: 161.w,
                child: Text(
                  '회원가입',
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
            ],
          );
        },
      ),
    );
  }
}