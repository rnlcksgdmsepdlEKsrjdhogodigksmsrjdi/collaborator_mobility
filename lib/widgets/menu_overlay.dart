import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final String userName; // 상위에서 받은 이름 직접 사용
  final VoidCallback onLogout;

  const MenuOverlay({
    super.key, 
    required this.onClose,
    required this.onLogout,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
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

          // 사용자 이름 (상위에서 받은 값 직접 표시)
          Positioned(
            top: 58.h,
            left: 29.w,
            child: _text(userName, 30.sp, Colors.black, 0.66),
          ),

          // 기타 UI 요소들
          Positioned(
            top: 87.h, 
            left: 29.w, 
            child: _text('기본 정보 보기', 13.sp, const Color(0xFFD9D9D9), 1.53)
          ),
          Positioned(
            top: 120.h,
            left: 29.w,
            child: Transform.rotate(
              angle: -0.000004956 * (math.pi / 180),
              child: const Divider(color: Color(0xFFD9D9D9), thickness: 1),
            ),
          ),
          Positioned(
            top: 162.h, 
            left: 29.w, 
            child: _text('예약 내역', 23.sp, Colors.black, 0.87)
          ),
          Positioned(
            top: 196.h, 
            left: 31.w, 
            child: _text('FAQ', 23.sp, Colors.black, 0.87)
          ),
          Positioned(
            top: 260.h, 
            left: 29.w, 
            child: GestureDetector(
              onTap: () {
                onLogout();
                onClose();
              },
              child: _text('로그아웃', 17.sp, const Color(0xFF030361), 1.17)
            ),
          ),
          Positioned(
            top: 287.h, 
            left: 29.w, 
            child: _text('탈퇴하기', 17.sp, const Color(0xFFC10000), 1.17)
          ),
        ],
      ),
    );
  }

  // 텍스트 스타일 헬퍼 함수
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