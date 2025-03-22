import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_voice_tutor/components/stats_card.dart';

import '../components/word_card.dart';
import '../components/empty_state.dart';
import '../providers/words_provider.dart';
import '../providers/user_provider.dart';
import '../models/word.dart';

class HomeScreen extends ConsumerWidget {
  
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final wordState = ref.watch(wordProvider);
    final userStats = ref.watch(userStatsProvider);
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: () => Future.wait([
        ref.read(wordProvider.notifier).loadRecentWords(),
        ref.read(userStatsProvider.notifier).loadUserStats(),
      ]),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StatsCard(
              statsData: userStats,
            ),
          ),
          
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              l10n.recentVocabulary, 
              theme,
            ),
          ),
          
          _buildRecentWordList(wordState),
          
          SliverToBoxAdapter(
            child: const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWordList(AsyncValue<List<Word>> wordState) {
    return wordState.when(
      data: (words) {
        if (words.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.book,
              message: '最近追加された単語データがありません',
              subMessage: 'データを追加して単語帳を作りましょう',
            ),
          );
        }
        
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final word = words[index];
                return WordCard(
                  word: word,
                  onTap: () => context.push('/deck-detail/${word.source}'),
                );
              },
              childCount: words.length > 5 ? 5 : words.length,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text('単語データの読み込みに失敗しました: $error'),
        ),
      ),
    );
  }
}