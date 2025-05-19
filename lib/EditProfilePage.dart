import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobility/user_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;
  late TextEditingController _carNumberController;

  List<String> _carNumbers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
    _carNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _carNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';

    final userInfoAsync = ref.watch(userAdditionalInfoProvider(userId));
    final userEmailAsync = ref.watch(userEmailProvider(userId));

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: userInfoAsync.when(
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('로드 실패')),
                  data: (userInfo) {
                    if (mounted && userInfo != null) {
                      _nameController.text = userInfo['name'] ?? '';
                      _phoneController.text = userInfo['phone'] ?? '';
                      if (_carNumbers.isEmpty) {
                        final carNumbers = userInfo['carNumbers'];
                        if (carNumbers is List) {
                          _carNumbers = carNumbers.whereType<String>().toList();
                        } else if (carNumbers is String) {
                          _carNumbers = [carNumbers];
                        }
                      }
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          _buildInputField(label: '이름', controller: _nameController),
                          SizedBox(height: 20.h),
                          userEmailAsync.when(
                            loading: () => CircularProgressIndicator(),
                            error: (e, s) => Text('이메일 로드 실패'),
                            data: (email) => _buildReadOnlyField(label: '이메일', value: email ?? '이메일 없음'),
                          ),
                          SizedBox(height: 20.h),
                          _buildInputField(
                            label: '전화번호',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            '차량번호',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Paperlogy',
                              fontSize: 23.sp,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          ..._carNumbers.map((number) => Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: Container(
                                  width: double.infinity,
                                  height: 43.h,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFD9D9D9)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                                          child: Text(
                                            number,
                                            style: TextStyle(fontSize: 16.sp),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _carNumbers.remove(number);
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 16.w),
                                          child: SvgPicture.asset(
                                            'assets/images/minusIcon.svg',
                                            width: 20.w,
                                            height: 20.h,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                          Container(
                            width: double.infinity,
                            height: 43.h,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFD9D9D9)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                                    child: TextField(
                                      controller: _carNumberController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '차량번호를 입력하세요',
                                        hintStyle: TextStyle(color: Color(0xFFB4B4B4)),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _addCarNumber,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 16.w),
                                    child: SvgPicture.asset(
                                      'assets/images/plusIcon.svg',
                                      width: 20.w,
                                      height: 20.h,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: GestureDetector(
                  onTap: () => _updateProfile(ref, userId),
                  child: Container(
                    width: 350.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Color(0xFF030361),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Paperlogy',
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SvgPicture.asset(
              'assets/images/icon.svg',
              width: 28.w,
              height: 28.h,
            ),
          ),
          Spacer(),
          Text(
            '마이페이지',
            style: TextStyle(
              fontSize: 20.sp,
              fontFamily: 'Paperlogy',
              color: Colors.black,
            ),
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 23.sp,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          height: 43.h,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFD9D9D9)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '$label을 입력하세요',
                hintStyle: TextStyle(color: Color(0xFFB4B4B4)),
              ),
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 23.sp,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          height: 43.h,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFD9D9D9)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 16.sp, color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addCarNumber() {
    final newNumber = _carNumberController.text.trim();
    if (newNumber.isNotEmpty && !_carNumbers.contains(newNumber)) {
      setState(() {
        _carNumbers.add(newNumber);
        _carNumberController.clear();
      });
    }
  }

  

  Future<void> _updateProfile(WidgetRef ref, String userId) async {
    final updatedName = _nameController.text.trim();
    final updatedPhone = _phoneController.text.trim();

    try {
      
      final userRef = FirebaseDatabase.instance.ref('users/$userId/additionalInfo');

      await userRef.update({
        'name': updatedName,
        'phone': updatedPhone,
        'carNumbers': _carNumbers,
      });

      // 성공 시 사용자에게 피드백
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원 정보가 성공적으로 업데이트되었습니다.')),
        );
      }

      await Future.delayed(Duration(seconds: 1));
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      // 실패 시 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 실패: $e')),
        );
      }
    }
  }

}
