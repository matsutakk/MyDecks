import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_voice_tutor/providers/decks_provider.dart';

import '../models/deck.dart';
import '../models/word.dart';
import '../components/word_card.dart';
import '../components/empty_state.dart';


final wordListProvider = StreamProvider.family<List<Word>, String>((ref, deckId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('decks')
      .doc(deckId)
      .collection('words')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Word.fromFirestore(doc))
          .toList());
});

final filterStateProvider = StateProvider.autoDispose<String>((ref) => 'all');

class DeckDetailScreen extends ConsumerStatefulWidget {
  final String deckId;

  const DeckDetailScreen({
    super.key,
    required this.deckId,
  });

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  bool _showTitle = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 120 && _showTitle) {
      setState(() {
        _showTitle = false;
      });
    } else if (_scrollController.offset <= 120 && !_showTitle) {
      setState(() {
        _showTitle = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deckAsync = ref.watch(deckStreamProvider(widget.deckId));
    final wordAsync = ref.watch(wordListProvider(widget.deckId));
    final filterState = ref.watch(filterStateProvider);
    
    return Scaffold(
      body: deckAsync.when(
        data: (deck) {
          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                title: _showTitle ? null : Text(deck.title),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                    tooltip: _isSearching ? l10n.cancelSearch : l10n.search,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          break;
                        case 'delete':
                          _confirmDelete(context, deck);
                          break;
                        case 'add_word':
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
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildDeckHeader(context, deck),
                ),
              ),
              if (_isSearching)
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchVocabulary,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterHeaderDelegate(
                  child: _buildFilterBar(context),
                ),
              ),
            ],
            body: wordAsync.when(
              data: (wordList) {
                var filteredList = wordList;
                if (filterState != 'all') {
                  filteredList = filteredList
                      .where((v) => v.difficulty.toLowerCase() == filterState.toLowerCase())
                      .toList();
                }
                
                if (_isSearching && _searchController.text.isNotEmpty) {
                  final searchTerm = _searchController.text.toLowerCase();
                  filteredList = filteredList
                      .where((v) => 
                        v.word.toLowerCase().contains(searchTerm) ||
                        v.definition.values.any((def) => def.toLowerCase().contains(searchTerm))
                      )
                      .toList();
                }
                return _buildVocabularyList(context, filteredList);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  '${l10n.errorLoadingWords}: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            '${l10n.errorLoadingDeck}: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckHeader(BuildContext context, Deck deck) {
    final theme = Theme.of(context);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        if (deck.imageUrl != null)
          Image.network(
            deck.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: theme.colorScheme.primaryContainer,
              );
            },
          )
        else
          Container(
            color: theme.colorScheme.primaryContainer,
          ),
        
        // 暗い半透明オーバーレイ
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                deck.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (deck.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  deck.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 8),
              
              // 統計データ
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.book,
                    label: '${deck.wordCount} 単語',
                    color: theme.colorScheme.primary,
                  ),
                  // if (deck.language != null) ...[
                  //   const SizedBox(width: 8),
                  //   _buildStatChip(
                  //     icon: Icons.language,
                  //     label: deck.language!,
                  //     color: theme.colorScheme.secondary,
                  //   ),
                  // ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(filterStateProvider);
    
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: l10n.all,
                    value: 'all',
                    isSelected: filter == 'all',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: l10n.beginner,
                    value: 'beginner',
                    isSelected: filter == 'beginner',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: l10n.intermediate,
                    value: 'intermediate',
                    isSelected: filter == 'intermediate',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: l10n.advanced,
                    value: 'advanced',
                    isSelected: filter == 'advanced',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(filterStateProvider.notifier).state = selected ? value : 'all';
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildVocabularyList(BuildContext context, List<Word> vocabularyList) {
    final l10n = AppLocalizations.of(context)!;
    
    if (vocabularyList.isEmpty) {
      return EmptyState(
        icon: Icons.book_outlined,
        message: _isSearching ? l10n.noSearchResults : l10n.noWordsInDeck,
        subMessage: _isSearching ? l10n.tryDifferentSearch : l10n.addWordsToStartStudying,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vocabularyList.length,
      itemBuilder: (context, index) {
        final word = vocabularyList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WordCard(
            word: word,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Deck deck) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDeck),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteDeckConfirmation(deck.title)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deleteWarning,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (result == true) {
      _deleteDeck();
    }
  }

  Future<void> _deleteDeck() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(widget.deckId)
          .delete();

      final wordsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(widget.deckId)
          .collection('words');

      final wordsSnapshot = await wordsCollection.get();
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in wordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (wordsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Error deleting deck: $e');
    }
  }
}

// フィルターヘッダーのためのデリゲート
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context, 
    double shrinkOffset, 
    bool overlapsContent
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: overlapsContent 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] 
            : null,
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}