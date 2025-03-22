import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    
    if (languageState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }
    
    final safeNativeLanguage = _getSafeLanguage(
      languageState.nativeLanguage, 
      languageState.availableLanguages
    );
    
    final safeTargetLanguage = _getSafeLanguage(
      languageState.targetLanguage, 
      languageState.availableLanguages
    );

    return InkWell(
      onTap: () => _showLanguageSelectionDialog(context, ref),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$safeNativeLanguage → $safeTargetLanguage',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LanguageSelectionDialog();
      },
    );
  }

  String _getSafeLanguage(String language, List<String> availableLanguages) {
    return availableLanguages.contains(language)
        ? language
        : (availableLanguages.isNotEmpty ? availableLanguages.first : '日本語');
  }
}

class LanguageSelectionDialog extends ConsumerWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    
    final safeNativeLanguage = _getSafeLanguage(
      languageState.nativeLanguage, 
      languageState.availableLanguages
    );
    
    final safeTargetLanguage = _getSafeLanguage(
      languageState.targetLanguage, 
      languageState.availableLanguages
    );

    return AlertDialog(
      title: const Text('言語設定'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('母国語'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: safeNativeLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(languageProvider.notifier).updateUserLanguage(
                    nativeLanguage: newValue,
                  );
                }
              },
              items: languageState.availableLanguages
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            const Text('学習言語'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: safeTargetLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(languageProvider.notifier).updateUserLanguage(
                    targetLanguage: newValue,
                  );
                }
              },
              items: languageState.availableLanguages
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  String _getSafeLanguage(String language, List<String> availableLanguages) {
    return availableLanguages.contains(language)
        ? language
        : (availableLanguages.isNotEmpty ? availableLanguages.first : '日本語');
  }
}