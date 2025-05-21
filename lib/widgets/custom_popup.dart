import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomPopup extends StatefulWidget {
  final String label;

  const CustomPopup({super.key, required this.label});

  @override
  State<CustomPopup> createState() => _CustomPopupState();
}

class _CustomPopupState extends State<CustomPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  final Map<String, Map<String, String>> labelData = {
    '조선대학교 해오름관': {
      'name': '조선대학교 해오름관',
      'address': '광주 동구 조선대5길 31',
      'charger': '완속 충전기',
    },
    '조선대학교 중앙도서관': {
      'name': '조선대학교 중앙도서관',
      'address': '광주 동구 조선대 5길 19',
      'charger': '완속 충전기',
    },
    '조선대학교 IT융합대학': {
      'name': '조선대학교 IT융합대학',
      'address': '광주 동구 조선대 5길 65',
      'charger': '완속 충전기',
    },
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _scaleAnimation =
        Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = labelData[widget.label] ??
        {'name': '알 수 없음', 'address': '-', 'charger': '-'};

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            width: 270.w,
            height: 242.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color.fromRGBO(217, 217, 217, 1),
                width: 1,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 44.h,
                  left: 0,
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/images/place1.svg',
                          width: 24.w, height: 24.h),
                      SizedBox(width: 12.w),
                      Text(
                        data['name']!,
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontSize: 20.sp,
                          letterSpacing: -0.5,
                          height: 1,
                          color: Colors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 88.h,
                  left: 0,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 1.6.h,
                              left: 0.8.w,
                              child: SvgPicture.asset('assets/images/map3.svg'),
                            ),
                            Positioned(
                              top: 1.6.h,
                              left: 6.6.w,
                              child: SvgPicture.asset('assets/images/map2.svg'),
                            ),
                            Positioned(
                              top: 5.h,
                              left: 13.3.w,
                              child: SvgPicture.asset('assets/images/map1.svg'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 9.w),
                      Text(
                        data['address']!,
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontSize: 20.sp,
                          letterSpacing: -0.5,
                          height: 1,
                          color: Colors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ], 
                  ),
                ),
                Positioned(
                  top: 132.h,
                  left: 0,
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/images/charger.svg',
                          width: 24.w, height: 24.h),
                      SizedBox(width: 10.w),
                      Text(
                        data['charger']!,
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontSize: 20.sp,
                          letterSpacing: 0,
                          height: 1,
                          color: Colors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),

                // 확인 버튼 정중앙 정렬
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 17.h),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 87.w,
                        height: 43.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: const Color.fromRGBO(3, 3, 97, 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '확인',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontSize: 22.sp,
                            letterSpacing: -0.5,
                            height: 1,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
