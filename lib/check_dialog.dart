import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_service.dart';

class CarConfirmDialog extends StatelessWidget {
  final String location;

  const CarConfirmDialog({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 236.3.w,
        height: 230.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            SizedBox(
              width: 175.w,
              child: Text(
                '현재 입고된 차량이\n본인 차량이 맞습니까?',
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
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await firebaseService.updateCarNumberInput(location: location, value: true);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 95.w,
                    height: 43.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xFF030361),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '예',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                GestureDetector(
                  onTap: () async {
                    await firebaseService.updateCarNumberInput(location: location, value: false);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 95.w,
                    height: 43.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '아니오',
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
