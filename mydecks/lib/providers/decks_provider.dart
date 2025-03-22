import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_voice_tutor/models/deck.dart';
import 'package:my_voice_tutor/repositories/deck_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepositoryImpl();
});

final deckProvider = FutureProvider.family<Deck, String>((ref, deckId) {
  return ref.watch(deckRepositoryProvider).getDeck(deckId);
});

final deckStreamProvider = StreamProvider.family<Deck, String>((ref, deckId) {
  return ref.watch(deckRepositoryProvider).getDeckStream(deckId);
});


final allDecksProvider = FutureProvider<List<Deck>>((ref) {
  return ref.watch(deckRepositoryProvider).getAllDecks();
});

final allDecksStreamProvider = StreamProvider<List<Deck>>((ref) {
  return ref.watch(deckRepositoryProvider).getAllDecksStream();
});