import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FAQAnswerScreen extends StatelessWidget {
  final String question;
  final String answer;

  const FAQAnswerScreen({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: 390.w,
        height: 844.h,
        color: Colors.white,
        child: Stack(
          children: [
            // 뒤로가기 버튼
            Positioned(
              top: 50.h,
              left: 20.w,
              child: SizedBox(
                width: 28.w,
                height: 28.h,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SvgPicture.asset(
                    'assets/images/icon.svg',
                    width: 28.w,
                    height: 28.h,
                    semanticsLabel: 'icon',
                  ),
                ),
              ),
            ),

            // "FAQ" 제목
            Positioned(
              top: 52.h,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'FAQ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 20.sp,
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
              ),
            ),

            // 답변 박스
            Positioned(
              top: 102.h,
              left: 20.w,
              child: Container(
                width: 350.w,
                height: 66.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    // 수직 정렬 제거 (기본값: center → 제거)
                    children: [
                      // A 아이콘 원
                      Container(
                        width: 34.w,
                        height: 34.h,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(3, 3, 97, 1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 15.sp,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // 답변 텍스트
                      Expanded(
                        child: Text(
                          answer,
                          textAlign: TextAlign.left, // 수평 정렬은 왼쪽 정렬
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontSize: 15.sp,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
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
