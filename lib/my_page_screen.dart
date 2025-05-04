import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobility/user_providers.dart';

class MyPageScreen extends ConsumerWidget {
  final String userId;

  const MyPageScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUserInfo = ref.watch(userAdditionalInfoProvider(userId));
    final asyncEmailInfo = ref.watch(userEmailProvider(userId));

    return Scaffold(
      body: asyncUserInfo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('오류 발생: $error')),
        data: (userInfo) {
          final name = userInfo?['name'] ?? '이름 없음';
          final phone = userInfo?['phone'] ?? '전화번호 없음';
          final carNumbers = (userInfo?['carNumbers'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['차량번호 없음'];

          return asyncEmailInfo.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('오류 발생: $error')),
            data: (email) {
              final userEmail = email ?? '이메일 없음';

              return Container(
                width: 390.w,
                height: 844.h,
                color: Colors.white,
                child: Stack(
                  children: <Widget>[
                    // 뒤로가기 아이콘
                    Positioned(
                      top: 50.h,
                      left: 20.w,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: Container(
                          width: 28.w,
                          height: 28.h,
                          color: Colors.white,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 5.h,
                                left: 10.w,
                                child: SvgPicture.asset(
                                  'assets/images/icon.svg',
                                  width: 18.w,
                                  height: 18.h,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 마이페이지 타이틀
                    Positioned(
                      top: 50.h,
                      left: 151.w,
                      child: Text(
                        '마이페이지',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Paperlogy',
                          fontSize: 20.sp,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    // 항목 제목들
                    buildLabeledRow(top: 112.h, label: '이름'),
                    buildLabeledRow(top: 212.h, label: '이메일'),
                    buildLabeledRow(top: 313.h, label: '전화번호'),
                    buildLabeledRow(top: 412.h, label: '차량번호'),

                    // 항목 값들
                    buildValueText(top: 151.h, text: name),
                    buildValueText(top: 252.h, text: userEmail),
                    buildValueText(top: 352.h, text: phone),
                    buildCarNumberTexts(top: 452.h, carNumbers: carNumbers),

                    // 수정하기 버튼
                    Positioned(
                      top: 738.h,
                      left: 20.w,
                      child: Container(
                        width: 350.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(3, 3, 97, 1),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Center(
                          child: Text(
                            '수정하기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 1),
                              fontFamily: 'Paperlogy',
                              fontSize: 15.sp,
                              letterSpacing: -0.5,
                              fontWeight: FontWeight.normal,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildLabeledRow({required double top, required String label}) {
    return Positioned(
      top: top,
      left: 20.w,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Paperlogy',
          fontSize: 23.sp,
          letterSpacing: -0.5,
          height: 0.87,
        ),
      ),
    );
  }

  Widget buildValueText({required double top, required String text}) {
    return Positioned(
      top: top,
      left: 20.w,
      child: Container(
        width: 350.w,
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          borderRadius: BorderRadius.circular(5.r),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: const Color(0xFFD9D9D9),
            fontFamily: 'Paperlogy',
            fontSize: 20.sp,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
      ),
    );
  }

    Widget buildCarNumberTexts({required double top, required List<String> carNumbers}) {
    return Positioned(
      top: top,
      left: 20.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: carNumbers.map((number) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Container(
              width: 350.w,
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
                borderRadius: BorderRadius.circular(5.r),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                number,
                style: TextStyle(
                  color: const Color(0xFFD9D9D9),
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

}
