import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_database/firebase_database.dart'; // 추가
import 'ID_pop.dart';

class FindIDPage extends StatelessWidget {
  const FindIDPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '아이디 찾기',
          style: TextStyle(
              color: Colors.black, fontFamily: 'Paperlogy', fontSize: 20.sp),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: '이름',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Paperlogy',
                      fontSize: 15,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF030361)),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    hintText: "휴대전화번호 입력 ('-'제외)",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Paperlogy',
                      fontSize: 15,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF030361)),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20.w,
            top: 232.h,
            child: SizedBox(
              width: 350.w,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () async {
                  String name = nameController.text.trim();
                  String phone = phoneController.text.trim();

                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '이름과 전화번호를 모두 입력해주세요.',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontSize: 14.sp,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: 80.h,
                          left: 20.w,
                          right: 20.w,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // 🔍 Firebase 검색 로직
                  final dbRef = FirebaseDatabase.instance.ref("users");
                  final snapshot = await dbRef.get();

                  bool found = false;
                  String? foundEmail;

                  if (snapshot.exists) {
                    final data = snapshot.value as Map;

                    data.forEach((userId, userData) {
                      final additional = userData['additionalInfo'];
                      final basic = userData['basicInfo'];

                      if (additional != null &&
                          additional['name'] == name &&
                          additional['phone'] == phone) {
                        found = true;
                        foundEmail = basic['email'];
                      }
                    });
                  }

                  if (found && foundEmail != null) {
                    showDialog(
                      context: context,
                      builder: (context) => IDPopupDialog(email: foundEmail!),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => const IDPopupDialog(email: '일치하는 정보가 없습니다.'),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF030361),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  '아이디 찾기',
                  style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 16.sp,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
