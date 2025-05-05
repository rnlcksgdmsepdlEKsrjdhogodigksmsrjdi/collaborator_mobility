import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../my_page_screen.dart';
import '../widgets/delete_user_popup.dart';

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

  void _showLogoutDialog(BuildContext context, VoidCallback onLogout, VoidCallback onClose) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 236.34.w,
          height: 230.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          ),
          child: Stack(
            children: [
              // 메시지 텍스트 (80.h 위치로 변경)
              Positioned(
                top: 80.h,
                left: 0,
                right: 0,
                child: const Text(
                  '로그아웃하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Paperlogy',
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
              ),

              // 버튼 영역 (146.h 고정 위치)
              Positioned(
                top: 146.h, // 버튼 높이 고정
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 확인 버튼
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onLogout();
                        onClose();
                      },
                      child: Container(
                        width: 95.w,
                        height: 43.h,
                        margin: EdgeInsets.only(right: 12.w), // 버튼 간격
                        decoration: BoxDecoration(
                          color: const Color(0xFF030361),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Paperlogy',
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ),
                    ),

                    // 취소 버튼
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 95.w,
                        height: 43.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Paperlogy',
                            color: Colors.black,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DeleteDialog(context: context);  // DeleteDialog 호출
      },
    );
  }


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
            child: Container(
              width: 333.w, // SVG의 width
              height: 844.h, // SVG의 height
              color: Colors.white, // fill="white"
            ),
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
                    SizedBox(height: 10.h), // 여백
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
            top: 182.h, 
            left: 29.w,
            child: _text('예약 내역', 23.sp, Colors.black, 0.87),
          ),

          // FAQ
          Positioned(
            top: 221.h, // 기존 196.h → 아래로 10
            left: 31.w,
            child: _text('FAQ', 23.sp, Colors.black, 0.87),
          ),

          // 로그아웃
          Positioned(
            top: 280.h, // 기존 260.h → 아래로 10
            left: 29.w,
            child: GestureDetector(
              onTap: () {
                _showLogoutDialog(context, onLogout, onClose);
              },
              child: _text('로그아웃', 17.sp, const Color(0xFF030361), 1.17),
            ),
          ),

          // 탈퇴하기
          Positioned(
            top: 312.h, // 기존 287.h → 아래로 10
            left: 29.w,
            child: GestureDetector(
              onTap: () {
                  _showDeleteDialog(context);
              },
              child: _text('탈퇴하기', 17.sp, const Color(0xFFC10000), 1.17),
            ),
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
