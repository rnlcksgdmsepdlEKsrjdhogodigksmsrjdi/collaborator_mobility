import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_service.dart';

class CarConfirmDialog extends StatelessWidget {
  final String location;

  const CarConfirmDialog({super.key, required this.location});

  @override
  Widget build(BuildContext context){
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
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 80.h,
              left: 32.3.w,
              child: SizedBox(
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
            ),
            Positioned(
              top: 146.h,
              left : 18.3.w,
              child: GestureDetector(
                onTap: () async {
                  await firebaseService.updateCarNumberInput(location: location, value: true);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 95.w,
                  height: 43.h,
                  decoration:BoxDecoration(
                    color: Color(0xFF030361),
                    borderRadius: BorderRadius.circular(10),
                  ) ,
                ),
              ),
            ),
            Positioned(
              top: 146.h,
              left: 125.3.w,
              child: GestureDetector(
                onTap: () async {
                  await firebaseService.updateCarNumberInput(location: location, value: false);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 95.w,
                  height: 43.h,
                  decoration: BoxDecoration(
                    color: Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 157.h,
              left: 56.3.w,
              child: Text(
                '예',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 157.h,
              left: 146.3.w,
              child: Text(
                '아니오',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  color: Colors.black,
                  letterSpacing: -0.5,
                  height:1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}