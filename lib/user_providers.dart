import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_repository.dart';

// UserRepository Provider
final userRepositoryProvider = Provider((ref) => UserRepository());

// 사용자 추가 정보 Provider
final userAdditionalInfoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getUserAdditionalInfo(userId);
});

final userEmailProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, userId) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getUserEmail(userId);
});
