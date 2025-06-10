import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BanChecker {
  static Future<void> checkAndBanUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) return;

    try {
      // bannedCars 전체 조회
      final bannedSnap = await FirebaseDatabase.instance.ref('bannedCars').once();

      if (bannedSnap.snapshot.exists) {
        final bannedMap = Map<String, dynamic>.from(bannedSnap.snapshot.value as Map);

        // 차량별 uid를 검사
        for (final entry in bannedMap.entries) {
          final carData = Map<String, dynamic>.from(entry.value);
          final bannedUid = carData['uid'];

          if (bannedUid == userId) {
            // 이 사용자에 대한 제재 조치 수행
            await showBannedDialog(context);

            // 사용자 데이터 삭제
            await FirebaseDatabase.instance.ref('users/$userId').remove();
            await user!.delete();

            // 로그인 페이지로 이동
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }

            return; // 탈퇴 처리 후 종료
          }
        }
      }
    } catch (e) {
      debugPrint("BanChecker error: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('에러가 발생했습니다. 다시 로그인 후 시도해주세요.')),
        );
      }
    }
  }

  static Future<void> showBannedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BannedDialog(),
    );
  }
}



class BannedDialog extends StatelessWidget {
  const BannedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 236.34.w,
        height: 230.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '경고 3회 누적되어\n이용이 정지되었습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                  color: Colors.black,
                  height: 1,
                ),
              ),
              SizedBox(height: 40.h),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 95.w,
                  height: 43.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF030361),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '예',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 20.sp,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
