import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:my_voice_tutor/repositories/user_repository.dart';

class LanguageState {
  final String nativeLanguage;
  final String targetLanguage;
  final List<String> availableLanguages;
  final Map<String, String> languageCodes;
  final bool isLoading;

  LanguageState({
    required this.nativeLanguage,
    required this.targetLanguage,
    required this.availableLanguages,
    required this.languageCodes,
    this.isLoading = false,
  });

  LanguageState copyWith({
    String? nativeLanguage,
    String? targetLanguage,
    List<String>? availableLanguages,
    Map<String, String>? languageCodes,
    bool? isLoading,
  }) {
    return LanguageState(
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      languageCodes: languageCodes ?? this.languageCodes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final userRepositoryProvider = Provider((ref) => UserRepositoryImpl());

class LanguageNotifier extends StateNotifier<LanguageState> {
  final UserRepository _repository;
  final logger = Logger();

  LanguageNotifier(this._repository) : super(LanguageState(
    nativeLanguage: 'Japanese',
    targetLanguage: 'English',
    availableLanguages: [
      'Japanese',
      'English',
      'Chinese',
      'Spanish',
      'French',
      'German',
      'Italian',
      'Portuguese',
      'Russian',
      'Arabic',
      'Korean',
      'Hindi',
      'Indonesian',
      'Vietnamese',
      'Thai',
      'Turkish',
      'Dutch', 
      'Swedish', 
      'Greek', 
      'Polish',
      'Danish',
      'Norwegian',
      'Finnish',
      'Czech',
      'Hungarian',
      'Hebrew',
      'Ukrainian',
      'Romanian',
      'Malay',
      'Tagalog',
    ],
    languageCodes: {
      'Japanese': 'ja',
      'English': 'en',
      'Chinese': 'zh',
      'Spanish': 'es',
      'French': 'fr',
      'German': 'de',
      'Italian': 'it',
      'Portuguese': 'pt',
      'Russian': 'ru',
      'Arabic': 'ar',
      'Korean': 'ko',
      'Hindi': 'hi',
      'Indonesian': 'id',
      'Vietnamese': 'vi',
      'Thai': 'th',
      'Turkish': 'tr',
      'Dutch': 'nl',
      'Swedish': 'sv',
      'Greek': 'el',
      'Polish': 'pl',
      'Danish': 'da',
      'Norwegian': 'no',
      'Finnish': 'fi',
      'Czech': 'cs',
      'Hungarian': 'hu',
      'Hebrew': 'he',
      'Ukrainian': 'uk',
      'Romanian': 'ro',
      'Malay': 'ms',
      'Tagalog': 'tl',
    },
    isLoading: true,
  )) {
    _loadLanguageSettings();
  }

  Future<void> _loadLanguageSettings() async {
    try {
      final settings = await _repository.getUserLanguageSettings();
      
      final nativeCode = settings['nativeLanguage'] ?? 'ja';
      final targetCode = settings['targetLanguage'] ?? 'en';
      String nativeName = 'Japanese';
      String targetName = 'English';
      
      state.languageCodes.forEach((name, code) {
        if (code == nativeCode) nativeName = name;
        if (code == targetCode) targetName = name;
      });
      
      state = state.copyWith(
        nativeLanguage: nativeName,
        targetLanguage: targetName,
        isLoading: false,
      );
    } catch (e) {
      logger.e('言語設定の読み込みに失敗しました: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateUserLanguage({String? nativeLanguage, String? targetLanguage}) async {
    if (state.nativeLanguage == nativeLanguage && state.targetLanguage == targetLanguage) {
      return;
    }
  
    try {
      state = state.copyWith(
        nativeLanguage: nativeLanguage,
        targetLanguage: targetLanguage,
        isLoading: true
      );

      final nativeCode = nativeLanguage != null ? state.languageCodes[nativeLanguage] : null;
      final targetCode = targetLanguage != null ? state.languageCodes[targetLanguage] : null;

      await _repository.updateUserLanguage(
        nativeLanguage: nativeCode,
        targetLanguage: targetCode
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      logger.e('言語設定の更新に失敗しました: $e');
      await _loadLanguageSettings();
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return LanguageNotifier(repository);
});