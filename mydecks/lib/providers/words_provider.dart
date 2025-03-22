import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../repositories/word_repository.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepositoryImpl();
});

final wordProvider = AsyncNotifierProvider<WordNotifier, List<Word>>(() {
  return WordNotifier();
});

class WordNotifier extends AsyncNotifier<List<Word>> {
  @override
  Future<List<Word>> build() async {
    return [];
  }
  
  Future<void> loadRecentWords() async {
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(wordRepositoryProvider);
      final words = await repository.getRecentWords();
      state = AsyncValue.data(words);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}