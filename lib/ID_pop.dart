import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IDPopupDialog extends StatelessWidget {
  final String email;
  const IDPopupDialog({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 236.34.w,
        height: 230.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 3),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 25.h),
            Text(
              '아이디',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Paperlogy',
                fontSize: 18.sp,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            // 이메일 중앙 정렬
            Expanded(
              child: Center(
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Paperlogy',
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 95.w,
              height: 43.h,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF030361),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Paperlogy',
                    fontSize: 20.sp,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
