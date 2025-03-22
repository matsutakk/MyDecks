import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

final currentUserProvider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isLoggedInProvider = Provider<bool>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

final userStatsProvider = AsyncNotifierProvider<UserStatsNotifier, Map<String, dynamic>>(() {
  return UserStatsNotifier();
});

class UserStatsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (!isLoggedIn) {
      return {};
    }
    
    return loadUserStats();
  }
  
  Future<Map<String, dynamic>> loadUserStats() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(userRepositoryProvider);
      final progress = await repository.getUserStats();
      state = AsyncValue.data(progress);
      return progress;
    } catch (e) {
      return {
        'deckCount': 0,
        'totalWords': 0,
      };
    }
  }
  
  Future<void> refreshProgress() async {
    state = const AsyncValue.loading();
    
    try {
      final newProgress = await loadUserStats();
      state = AsyncValue.data(newProgress);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}