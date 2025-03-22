import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsCard extends ConsumerWidget {
  final AsyncValue<Map<String, dynamic>> statsData;
  
  const StatsCard({
    super.key,
    required this.statsData,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statsData.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '単語帳の概要',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProgressItem('単語帳', '${data['deckCount'] ?? 0}冊', Icons.book, secondaryColor),
                  _buildProgressItem('総単語数', '${data['totalWords'] ?? 0}語', Icons.format_list_bulleted, secondaryColor),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     _buildStatItem('最近の学習', '${data['recentLearnDays'] ?? 0}日連続', Icons.timeline),
              //     _buildStatItem('お気に入り', '${data['favoriteWords'] ?? 0}語', Icons.favorite),
              //   ],
              // ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('データの読み込みに失敗しました'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressItem(String label, String value, IconData icon, Color accentColor) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}