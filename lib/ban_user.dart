import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
            // 🚫 이 사용자에 대한 제재 조치 수행
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('이용 불가'),
                content: const Text('경고 3회 누적으로 인해 탈퇴 처리되었습니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );

            // 🔥 사용자 데이터 삭제
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
}
