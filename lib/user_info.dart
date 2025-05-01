import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_database/firebase_database.dart';

class UserInfoScreen extends StatefulWidget {
  final String userId;
  
  const UserInfoScreen({super.key, required this.userId});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentCarController = TextEditingController();
  final List<String> _carNumbers = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentCarController.dispose();
    super.dispose();
  }

  void _addCarNumber() {
    if (_currentCarController.text.isNotEmpty) {
      setState(() {
        _carNumbers.add(_currentCarController.text);
        _currentCarController.clear();
      });
    }
  }

  void _removeCarNumber(int index) {
    setState(() {
      _carNumbers.removeAt(index);
    });
  }

  Future<void> _saveUserData() async {
  final name = _nameController.text.trim();
  final phone = _phoneController.text.trim();
  final tempCar = _currentCarController.text.trim();

  // 차량 번호가 하나라도 입력되었으면 _carNumbers에 추가 (plus 버튼 안 눌러도)
  if (tempCar.isNotEmpty && !_carNumbers.contains(tempCar)) {
    _carNumbers.add(tempCar);
  }

  if (name.isEmpty || phone.isEmpty || _carNumbers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이름, 전화번호, 차량번호를 모두 입력해주세요')));
    return;
  }

  setState(() => _isSaving = true);

  try {
    await FirebaseDatabase.instance
        .ref('users/${widget.userId}/additionalInfo')
        .set({
          'name': name,
          'phone': phone,
          'carNumbers': _carNumbers,
          'createdAt': ServerValue.timestamp,
        });

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.toString()}'))); // 에러 핸들링
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 30.h),
            Text(
              '회원정보 입력',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 20.sp,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),
            Text(
              'PIKA.EV',
              style: TextStyle(
                fontFamily: 'Gmarket Sans TTF',
                fontSize: 30.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 30.h),

            // 이름 입력 필드
            _buildInputField(
              controller: _nameController,
              hintText: '이름 입력',
            ),
            SizedBox(height: 10.h),

            // 전화번호 입력 필드
            _buildInputField(
              controller: _phoneController,
              hintText: '전화번호 입력',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10.h),

            // 차량번호 입력 필드
            _buildCarInputField(),
            SizedBox(height: 10.h),

            // 입력된 차량번호 목록
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
                itemCount: _carNumbers.length,
                itemBuilder: (context, index) => _buildCarNumberItem(index),
              ),
            ),

            // 저장하기 버튼
            _buildSaveButton(),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 43.h,
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(217, 217, 217, 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: _inputTextStyle(),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          isCollapsed: true,
          hintStyle: _hintTextStyle(),
        ),
      ),
    );
  }

  Widget _buildCarInputField() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20.w),
    height: 43.h,
    decoration: BoxDecoration(
      border: Border.all(
        color: const Color.fromRGBO(217, 217, 217, 1),
        width: 1,
      ),
    ),
    child: Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 10.w, right: 40.w, top: 10.h), // 아이콘 공간 확보
          child: TextField(
            controller: _currentCarController,
            style: _inputTextStyle(),
            decoration: InputDecoration(
              hintText: '차량번호 입력',
              border: InputBorder.none,
              isCollapsed: true,
              hintStyle: _hintTextStyle(),
            ),
          ),
        ),
        Positioned(
          top: 11.h,
          right: 10.w,
          child: GestureDetector(
            onTap: _addCarNumber,
            child: SizedBox(
              width: 20.w,
              height: 20.h,
              child: SvgPicture.asset(
                'assets/images/plusIcon.svg',
                semanticsLabel: 'plus',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCarNumberItem(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      height: 43.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromRGBO(217, 217, 217, 1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.w, top: 10.h),
            child: Text(
              _carNumbers[index],
              style: _inputTextStyle(),
            ),
          ),
          Positioned(
            top: 11.h,
            right: 10.w,
            child: GestureDetector(
              onTap: () => _removeCarNumber(index),
              child: SizedBox(
                width: 20.w,
                height: 20.h,
                child: SvgPicture.asset(
                  'assets/images/minusIcon.svg',
                  semanticsLabel: 'minus',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 50.h,
      color: const Color.fromRGBO(3, 3, 97, 1),
      child: TextButton(
        onPressed: _isSaving ? null : _saveUserData,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                '저장하기',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                ),
              ),
      ),
    );
  }

  TextStyle _inputTextStyle() {
    return TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: 20.sp,
      color: Colors.black,
      height: 1,
    );
  }

  TextStyle _hintTextStyle() {
    return TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: 20.sp,
      color: const Color.fromRGBO(217, 217, 217, 1),
      height: 1,
    );
  }
}