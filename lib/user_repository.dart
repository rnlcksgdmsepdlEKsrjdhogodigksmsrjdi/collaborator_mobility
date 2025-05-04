// user_repository.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class UserRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // 사용자 추가 정보 저장
  Future<void> saveUserAdditionalInfo({
    required String userId,
    required String name,
    required String phone,
    required List<String> carNumbers,
  }) async {
    await _db.child('users/$userId/additionalInfo').set({
      'name': name,
      'phone': phone,
      'carNumbers': carNumbers,
      'createdAt': ServerValue.timestamp,
    });
  }

Future<String?> getUserEmail(String userId) async{
  try {
    final snapshot = await _db.child('users/$userId/basicInfo/email').get();

    if(!snapshot.exists){
      debugPrint('데이터가 존재하지 않습니다');
      return null;
    }

    final email = snapshot.value;
    if(email is String){
      return email;
    }
    else {
      debugPrint('이메일 데이터 형식이 잘못되었습니다');
      return null;
    }
  }
  catch (e, stackTrace){
    debugPrint('Error loading email: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}

  // 사용자 추가 정보 불러오기
  // user_repository.dart
Future<Map<String, dynamic>?> getUserAdditionalInfo(String userId) async {
  try {
    final snapshot = await _db.child('users/$userId/additionalInfo').get();
    
    if (!snapshot.exists) {
      debugPrint('데이터가 존재하지 않습니다');
      return null;
    }

    final data = snapshot.value;
    if (data is Map) {
      return data.cast<String, dynamic>(); // 안전한 타입 변환
    }
    return null;
  } catch (e, stackTrace) {
    debugPrint('Error loading user info: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}
}