import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobility/services/account_delete.dart';

class DeleteDialog extends StatelessWidget {
  final BuildContext context;

  const DeleteDialog({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
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
            // 메시지 텍스트
            Positioned(
              top: 80.h,
              left: 0,
              right: 0,
              child: const Text(
                '서비스에 탈퇴하시겠습니까?',
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
            // 버튼 영역
            Positioned(
              top: 146.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 탈퇴 버튼
                  GestureDetector(
                    onTap: () {
                      UserService().deleteUserAccount(context).then((_) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (_) => false);
                      });
                    },
                    child: Container(
                      width: 95.w,
                      height: 43.h,
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF030361),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '탈퇴',
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
  }
}
