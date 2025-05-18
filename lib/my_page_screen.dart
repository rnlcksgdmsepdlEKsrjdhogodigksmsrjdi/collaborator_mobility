import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobility/EditProfilePage.dart';
import 'package:mobility/reauthenticateUser.dart';
import 'package:mobility/user_providers.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  final String userId;

  const MyPageScreen({super.key, required this.userId});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool isEditing = false;
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _navigateToEditPage(BuildContext context) async {
    final isAuthenticated = await _authService.reauthenticateUser(context);

    if(isAuthenticated){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditProfilePage()),
      );
    }

  }
  

  @override
  Widget build(BuildContext context) {
    final asyncUserInfo = ref.watch(userAdditionalInfoProvider(widget.userId));
    final asyncEmailInfo = ref.watch(userEmailProvider(widget.userId));

    return Scaffold(
      body: asyncUserInfo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('오류 발생: $error')),
        data: (userInfo) {
          final name = userInfo?['name'] ?? '이름 없음';
          final phone = userInfo?['phone'] ?? '전화번호 없음';
          final carNumbers = (userInfo?['carNumbers'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

          _nameController.text = name;
          _phoneController.text = phone;

          return asyncEmailInfo.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('오류 발생: $error')),
            data: (email) {
              final userEmail = email ?? '이메일 없음';
              _emailController.text = userEmail;

              return Container(
                width: 390.w,
                height: 844.h,
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned(
                      top: 50.h,
                      left: 20.w,
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                        child: SvgPicture.asset('assets/images/icon.svg', width: 28.w, height: 28.h),
                      ),
                    ),
                    Positioned(
                      top: 50.h,
                      left: 151.w,
                      child: Text(
                        '마이페이지',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Paperlogy',
                          fontSize: 20.sp,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    buildLabeledRow(top: 112.h, label: '이름'),
                    buildLabeledRow(top: 212.h, label: '이메일'),
                    buildLabeledRow(top: 313.h, label: '전화번호'),
                    buildLabeledRow(top: 412.h, label: '차량번호'),

                    isEditing
                        ? buildTextField(top: 151.h, controller: _nameController)
                        : buildValueText(top: 151.h, text: name),
                    isEditing
                        ? buildTextField(top: 252.h, controller: _emailController)
                        : buildValueText(top: 252.h, text: userEmail),
                    isEditing
                        ? buildTextField(top: 352.h, controller: _phoneController)
                        : buildValueText(top: 352.h, text: phone),
                    buildCarNumberTexts(top: 452.h, carNumbers: carNumbers),

                    Positioned(
                      top: 738.h,
                      left: 20.w,
                      child: GestureDetector(
                        onTap: () => _navigateToEditPage(context),
                        child: Container(
                          width: 350.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF030361),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Center(
                            child: Text(
                              '수정하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Paperlogy',
                                fontSize: 15.sp,
                                letterSpacing: -0.5,
                              ),
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
          ),
        ),
      ),
    );
  }

  Widget buildTextField({required double top, required TextEditingController controller}) {
    return Positioned(
      top: top,
      left: 20.w,
      child: Container(
        width: 350.w,
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF030361), width: 1),
          borderRadius: BorderRadius.circular(5.r),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 20.sp,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
          decoration: const InputDecoration(border: InputBorder.none),
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
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
