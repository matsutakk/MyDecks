import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_voice_tutor/providers/decks_provider.dart';

import '../models/deck.dart';
import '../components/empty_state.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final decksAsync = ref.watch(allDecksStreamProvider);

    return Scaffold(
      body: decksAsync.when(
        data: (decks) {
          if (decks.isEmpty) {
            return _buildEmptyState(context, l10n);
          }
          return _buildDeckList(context, decks, l10n, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '${l10n.errorLoadingDecks}: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return EmptyState(
      icon: Icons.book_outlined,
      message: l10n.noDeckYet,
      subMessage: l10n.tapPlusToCreateDeck,
    );
  }

  Widget _buildDeckList(
    BuildContext context,
    List<Deck> decks,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allDecksProvider);
        return ref.read(allDecksProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                context.push('/deck-detail/${deck.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deck.imageUrl != null)
                    Image.network(
                      deck.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                deck.title,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildPopupMenu(context, deck, l10n),
                          ],
                        ),
                        if (deck.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            deck.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.wordsCount(deck.wordCount),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _formatDate(deck.updatedAt, l10n),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    Deck deck,
    AppLocalizations l10n,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            break;
          case 'delete':
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteDeck),
                content: Text(l10n.deleteDeckConfirmation(deck.title)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            );
            
            if (confirm == true) {
              _deleteDeck(deck.id);
            }
            break;
          case 'share':
            break;
          case 'export':
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return l10n.justNow;
        }
        return l10n.minutesAgo(difference.inMinutes);
      }
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  Future<void> _deleteDeck(String deckId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(deckId)
          .delete();

      final wordsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(deckId)
          .collection('words');

      final wordsSnapshot = await wordsCollection.get();
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in wordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (wordsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error deleting deck: $e');
    }
  }
}