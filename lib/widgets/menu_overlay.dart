import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../my_page_screen.dart';

class MenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final String userName;
  final VoidCallback onLogout;

  const MenuOverlay({
    super.key, 
    required this.onClose,
    required this.onLogout,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Container(
      width: 333.w,
      height: 844.h,
      decoration: const BoxDecoration(),
      child: Stack(
        children: [
          // 배경 이미지
          Positioned(
            top: 0.h,
            left: 0.w,
            child: SvgPicture.asset('assets/images/Rectangle 18.svg'),
          ),

          Positioned(
            top: 68.h, // 기존보다 살짝 내려줌
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPageScreen(userId: userId,)),
                );
                print("마이페이지 이동");
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 29.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(userName, 30.sp, Colors.black, 0.66),
                    SizedBox(height: 8.h), // 여백
                    _text('기본 정보 보기', 13.sp, const Color(0xFFD9D9D9), 1.53),
                    SizedBox(height: 22.h), // 여백
                  ],
                ),
              ),
            ),
          ),

          // 구분선 (Divider)
          Positioned(
            top: 127.h, 
            left: 29.w,
            right: 29.w, 
            child: Container(
              height: 1.h,
              color: const Color(0xFFD9D9D9),
            ),
          ),

          // 예약 내역
          Positioned(
            top: 172.h, 
            left: 29.w,
            child: _text('예약 내역', 23.sp, Colors.black, 0.87),
          ),

          // FAQ
          Positioned(
            top: 206.h, // 기존 196.h → 아래로 10
            left: 31.w,
            child: _text('FAQ', 23.sp, Colors.black, 0.87),
          ),

          // 로그아웃
          Positioned(
            top: 270.h, // 기존 260.h → 아래로 10
            left: 29.w,
            child: GestureDetector(
              onTap: () {
                onLogout();
                onClose();
              },
              child: _text('로그아웃', 17.sp, const Color(0xFF030361), 1.17),
            ),
          ),

          // 탈퇴하기
          Positioned(
            top: 297.h, // 기존 287.h → 아래로 10
            left: 29.w,
            child: _text('탈퇴하기', 17.sp, const Color(0xFFC10000), 1.17),
          ),
        ],
      ),
    );
  }

  Widget _text(String text, double size, Color color, double height) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontFamily: 'Paperlogy',
        letterSpacing: -0.5,
        height: height,
      ),
    );
  }
}
