import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_voice_tutor/models/deck.dart';

abstract class DeckRepository {
  Future<Deck> getDeck(String deckId);
  Future<List<Deck>> getAllDecks();
  Stream<Deck> getDeckStream(String deckId);
  Stream<List<Deck>> getAllDecksStream();
}

class DeckRepositoryImpl extends DeckRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DeckRepositoryImpl();

  String? get _userId => _auth.currentUser?.uid;

  // Get a deck with its words count
  @override
  Future<Deck> getDeck(String deckId) async {
    if (_userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    final docSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('decks')
        .doc(deckId)
        .get();
    final data = docSnapshot.data() as Map<String, dynamic>;
    
    // Get words subcollection count
    final wordsSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('decks')
        .doc(deckId)
        .collection('words')
        .get();
    
    return Deck(
      id: docSnapshot.id,
      title: data['title'] ?? '作成中',
      description: data['description'] ?? '',
      fileType: data['fileType'],
      wordCount: wordsSnapshot.size,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  // Get all decks with their words counts
  @override
  Future<List<Deck>> getAllDecks() async {
    if (_userId == null) {
      throw Exception('ユーザーが認証されていません');
    }

    final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('decks')
          .orderBy('createdAt', descending: true)
          .get();
    List<Deck> decks = [];
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final wordsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('decks')
          .doc(doc.id)
          .collection('words')
          .get();
      
      decks.add(
        Deck(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          fileType: data['fileType'] ?? '',
          wordCount: wordsSnapshot.size,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          imageUrl: data['imageUrl'],
        )
      );
    }
    return decks;
  }

  @override
  Stream<Deck> getDeckStream(String deckId) {
    if (_userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    final deckDoc = _firestore
        .collection('users')
        .doc(_userId)
        .collection('decks')
        .doc(deckId);
    
    return deckDoc.snapshots().asyncMap((deckSnapshot) async {
      if (!deckSnapshot.exists) {
        throw Exception('デッキが見つかりません');
      }
      
      final data = deckSnapshot.data() as Map<String, dynamic>;
      
      final wordsSnapshot = await deckDoc
          .collection('words')
          .get();
      
      return Deck(
        id: deckSnapshot.id,
        title: data['title'] ?? '作成中',
        description: data['description'] ?? '',
        fileType: data['fileType'],
        wordCount: wordsSnapshot.size,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        imageUrl: data['imageUrl'],
      );
    });
  }

  @override
  Stream<List<Deck>> getAllDecksStream() {
    if (_userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    final decksCollection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('decks')
        .orderBy('createdAt', descending: true);
    
    return decksCollection.snapshots().asyncMap((snapshot) async {
      List<Deck> decks = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final wordsSnapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('decks')
            .doc(doc.id)
            .collection('words')
            .get();
        
        decks.add(
          Deck(
            id: doc.id,
            title: data['title'] ?? '作成中',
            description: data['description'] ?? '',
            fileType: data['fileType'] ?? '',
            wordCount: wordsSnapshot.size,
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
            imageUrl: data['imageUrl'],
          )
        );
      }
      return decks;
    });
  }
}