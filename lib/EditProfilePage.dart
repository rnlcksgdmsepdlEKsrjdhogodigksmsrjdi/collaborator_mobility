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

    // 사용자 추가 정보 로드
    final userInfoAsync = ref.watch(userAdditionalInfoProvider(userId));
    final userEmailAsync = ref.watch(userEmailProvider(userId));

    // 데이터가 로드되면 컨트롤러에 값 설정
    userInfoAsync.whenData((userInfo) {
      if (userInfo != null) {
        _nameController.text = userInfo['name'] ?? '';
        _phoneController.text = userInfo['phone'] ?? '';
        
        // 차량번호 리스트 업데이트
        final carNumbers = userInfo['carNumbers'];
        if (carNumbers is List) {
          _carNumbers = carNumbers.whereType<String>().toList();
        } else if (carNumbers is String) {
          _carNumbers = [carNumbers];
        }
      }
    });

    return Scaffold(
      body: Container(
        width: 390.w,
        height: 844.h,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 1),
        ),
        child: Stack(
          children: <Widget>[
            // Back button
            Positioned(
              top: 45.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28.w,
                  height: 28.h,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 1),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: 5.h,
                        left: 10.w,
                        child: SvgPicture.asset(
                          'assets/images/icon.svg',
                          semanticsLabel: 'icon',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Title
            Positioned(
              top: 49.h,
              left: 151.w,
              child: Text(
                '마이페이지',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
            
            // Name Section
            _buildInputField(
              top: 112.h,
              label: '이름',
              controller: _nameController,
            ),
            
            // Email Section (읽기 전용)
            userEmailAsync.when(
              loading: () => Positioned(
                top: 200.h,
                left: 20.w,
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Positioned(
                top: 200.h,
                left: 20.w,
                child: Text('이메일 로드 실패'),
              ),
              data: (email) => _buildReadOnlyField(
                top: 200.h,
                label: '이메일',
                value: email ?? '이메일 없음',
              ),
            ),
            
            // Phone Number Section
            _buildInputField(
              top: 476.h,
              label: '전화번호',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            
            // Car Number Section
            Positioned(
              top: 568.h,
              left: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '차량번호',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Paperlogy',
                      fontSize: 23.sp,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  
                  // 기존 차량번호 목록 표시
                  ..._carNumbers.map((number) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Container(
                      width: 350.w,
                      height: 43.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromRGBO(217, 217, 217, 1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  number,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 16.w),
                            child: GestureDetector(
                              onTap: () => _showDeleteConfirmationDialog(number),
                              child: Container(
                                width: 20.w,
                                height: 20.h,
                                child: SvgPicture.asset(
                                  'assets/images/minusIcon.svg',
                                  semanticsLabel: 'minus_icon',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                  
                  // 새로운 차량번호 입력 필드
                  Container(
                    width: 350.w,
                    height: 43.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromRGBO(217, 217, 217, 1),
                        width: 1,
                      ),
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
                                hintStyle: TextStyle(
                                  color: Color.fromRGBO(180, 180, 180, 1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 16.w),
                          child: GestureDetector(
                            onTap: _addCarNumber,
                            child: Container(
                              width: 20.w,
                              height: 20.h,
                              child: SvgPicture.asset(
                                'assets/images/plusIcon.svg',
                                semanticsLabel: 'plus_icon',
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
            
            // Confirm button
            Positioned(
              top: 738.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () => _updateProfile(ref, userId),
                child: Container(
                  width: 350.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF030361),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  void _showDeleteConfirmationDialog(String carNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('차량번호 삭제'),
          content: Text('정말로 이 차량번호를 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('삭제'),
              onPressed: () {
                setState(() {
                  _carNumbers.remove(carNumber);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField({
    required double top,
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Positioned(
      top: top,
      left: 20.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Paperlogy',
              fontSize: 23.sp,
              letterSpacing: -0.5,
              fontWeight: FontWeight.normal,
              height: 1,
            ),
          ),
          SizedBox(height: 5.h),
          Container(
            width: 350.w,
            height: 43.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: Color.fromRGBO(217, 217, 217, 1),
                width: 1,
              ),
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
                  hintStyle: TextStyle(
                    color: Color.fromRGBO(180, 180, 180, 1),
                  ),
                ),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required double top,
    required String label,
    required String value,
  }) {
    return Positioned(
      top: top,
      left: 20.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Paperlogy',
              fontSize: 23.sp,
              letterSpacing: -0.5,
              fontWeight: FontWeight.normal,
              height: 1,
            ),
          ),
          SizedBox(height: 5.h),
          Container(
            width: 350.w,
            height: 43.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: Color.fromRGBO(217, 217, 217, 1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(WidgetRef ref, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repo = ref.read(userRepositoryProvider);
    final Map<String, dynamic> updates = {};

    if (_nameController.text.isNotEmpty) {
      updates['name'] = _nameController.text;
    }

    if (_phoneController.text.isNotEmpty) {
      updates['phone'] = _phoneController.text;
    }

    if (_carNumbers.isNotEmpty) {
      updates['carNumbers'] = _carNumbers;
    }

    // 비밀번호 업데이트
    if (_passwordController.text.isNotEmpty && 
        _passwordController.text == _confirmPasswordController.text) {
      await user.updatePassword(_passwordController.text);
    }

    // 사용자 정보 업데이트
    if (updates.isNotEmpty) {
      await repo.updateUserAdditionalInfo(userId, updates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필이 업데이트되었습니다')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변경된 내용이 없습니다')),
      );
    }
  }
}