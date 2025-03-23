import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/word.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback? onTap;
  final FlutterTts flutterTts = FlutterTts();

  WordCard({
    super.key,
    required this.word,
    this.onTap
  });

  Future<void> _speak(String text) async {
    // await flutterTts.setLanguage(word.targetLanguage);
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        // onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (word.definition.isNotEmpty)
              _buildDefinitionsSection(context),
            if (word.examples.isNotEmpty)
              _buildExamplesSection(context),
            if (word.synonyms.isNotEmpty || word.antonyms.isNotEmpty)
              _buildSynonymsAntonymsSection(context),
            if (word.collocations.isNotEmpty)
              _buildCollocationsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.7),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    word.word,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    _speak(word.word);
                  },
                  tooltip: '発音を聞く',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          
          _buildDifficultyBadge(context, word.difficulty),
        ],
      ),
    );
  }

  Widget _buildDefinitionsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '定義',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 定義リストを表示
          ...word.definition.entries.map((entry) {
            return _buildDefinitionItem(context, entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_bulleted, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                '例文',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 例文リストを表示
          ...word.examples.map((example) {
            return _buildExampleItem(
              context,
              example,
              word.nativeLanguage,
              word.targetLanguage
            );
          }),
        ],
      ),
    );
  }

  // 類義語と反意語のセクション
  Widget _buildSynonymsAntonymsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 類義語セクション
          if (word.synonyms.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.compare_arrows, size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  '類義語',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.synonyms.map((synonym) {
                return _buildWordChip(context, synonym.word, theme.colorScheme.tertiary);
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // 反意語セクション
          if (word.antonyms.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.swap_horiz, size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  '反意語',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.antonyms.map((antonym) {
                return _buildWordChip(context, antonym.word, theme.colorScheme.error);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollocationsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 18, color: theme.colorScheme.primary.withBlue(220)),
              const SizedBox(width: 8),
              Text(
                'コロケーション',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary.withBlue(220),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...word.collocations.map((collocation) {
            return _buildCollocationItem(context, collocation);
          }),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context, String difficulty) {
    final theme = Theme.of(context);
    final color = _getDifficultyColor(difficulty);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        difficulty,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildDefinitionItem(BuildContext context, String language, String definition) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              language,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Text(
            definition,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem(
    BuildContext context, 
    Map<String, String> example,
    String nativeLanguage,
    String targetLanguage) {
    final theme = Theme.of(context);
    final sentenceNative = example[nativeLanguage] ?? '';
    final sentenceTarget = example[targetLanguage] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sentenceTarget,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: theme.colorScheme.secondary,
                  size: 18,
                ),
                onPressed: () {
                  _speak(sentenceTarget);
                },
                tooltip: '例文を聞く',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                iconSize: 18,
                splashRadius: 20,
              ),
            ],
          ),
          Text(
            sentenceNative,
            style: theme.textTheme.bodyMedium?.copyWith(
              // イタリック削除
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollocationItem(
    BuildContext context, 
    Collocation collocation) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withBlue(220).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withBlue(220).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    collocation.phrase,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary.withBlue(220),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: theme.colorScheme.primary.withBlue(220),
                  size: 18,
                ),
                onPressed: () {
                  _speak(collocation.phrase);
                },
                tooltip: 'コロケーションを聞く',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                iconSize: 18,
                splashRadius: 20,
              ),
            ],
          ),
          Text(
            collocation.translation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          if (collocation.example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withBlue(220).withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.primary.withBlue(220).withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Text(
                collocation.example,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWordChip(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        _speak(text);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.volume_up_outlined,
              size: 14,
              color: color.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green.shade700;
      case 'intermediate':
        return Colors.orange.shade700;
      case 'advanced':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}