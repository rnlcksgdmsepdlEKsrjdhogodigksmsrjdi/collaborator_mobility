import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobility/reservation.dart';
import '../widgets/custom_popup.dart';

class Frame28Widget extends StatelessWidget {
  const Frame28Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(217, 217, 217, 0.6),
            offset: Offset(0, 4.h),
            blurRadius: 13.r,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 21.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                ),
              ),
              SizedBox(height: 35.h),
              SizedBox(height: 30.h),
              Divider(color: const Color.fromRGBO(245, 245, 245, 1), thickness: 9.h),
              SizedBox(height: 20.h),

              // 목적지 목록들
              buildPlaceItem(context, 'assets/images/place1.svg', '조선대학교 해오름관'),
              buildPlaceItem(context, 'assets/images/place2.svg', '조선대학교 중앙도서관'),
              buildPlaceItem(context, 'assets/images/place3.svg', '조선대학교 IT융합대학'),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPlaceItem(BuildContext context, String iconPath, String label) {
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: "팝업",
                  barrierColor: const Color.fromRGBO(0, 0, 0, 0.4),
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, anim1, anim2) { 
                    return const SizedBox();
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return FadeTransition(
                      opacity: anim1,
                      child: CustomPopup(label: label),
                    );
                  },
                );
              },
              child: Row(
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 24.w,
                    height: 24.h,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Paperlogy',
                      fontSize: 20.sp,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: 76.w,
              height: 33.h,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(3, 3, 97, 1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationScreen(destination: label),
                    ),
                  );
                },
                child: Text(
                '예약하기',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Paperlogy',
                  fontSize: 15.sp,
                  letterSpacing: -0.5,
                  height: 1.33,
                ),
              ),
              )
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Divider(
          thickness: 1.h,
          color: const Color(0xFFD9D9D9),
          indent: 0,
          endIndent: 0,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
