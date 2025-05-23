import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'PW_pop.dart'; 

class FindpwPage extends StatelessWidget {
  const FindpwPage({super.key});

  Future<void> requestTempPassword(BuildContext context, String id, String name, String phone) async {
    if (id.isEmpty || name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '아이디와 이름과 전화번호를 모두 입력해주세요.',
            style: TextStyle(fontFamily: 'Paperlogy', fontSize: 14.sp),
          ),
        ),
      );
      return;
    }

    
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(id);
      if (!methods.contains('password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '소셜 로그인 계정은 비밀번호 재설정을 할 수 없습니다.',
              style: TextStyle(fontFamily: 'Paperlogy', fontSize: 14.sp),
            ),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계정 확인 중 오류 발생: $e')),
      );
      return;
    }

    
    try {
      final response = await http.post(
        Uri.parse('https://asia-northeast3-mobility-1997a.cloudfunctions.net/generateTempPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': id, 'name': name, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final tempPassword = json['tempPassword'];
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => PWPopupDialog(tempPassword: tempPassword),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("입력한 정보와 일치하는 계정을 찾을 수 없습니다.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Text(
          '비밀번호 찾기',
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 20.sp,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.h),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                hintText: '아이디',
                hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Paperlogy',
                    fontSize: 15),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF030361)),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: '이름',
                hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Paperlogy',
                    fontSize: 15),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF030361)),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                hintText: '전화번호',
                hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Paperlogy',
                    fontSize: 15),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF030361)),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                final id = idController.text.trim();
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                requestTempPassword(context, id, name, phone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF030361),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '임시 비밀번호 발급',
                style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 16.sp,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
