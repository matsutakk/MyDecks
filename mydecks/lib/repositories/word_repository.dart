import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/web.dart';
import '../models/word.dart';

abstract class WordRepository {
  Future<List<Word>> getRecentWords();
}

class WordRepositoryImpl implements WordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final logger = Logger();

  String? get _userId => _auth.currentUser?.uid;

  @override
  Future<List<Word>> getRecentWords() async {
    if (_userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    try {
      final deckSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('decks')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (deckSnapshot.docs.isNotEmpty) {
        final latestDeckId = deckSnapshot.docs.first.id;
  
        final wordsSnapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('decks')
            .doc(latestDeckId)
            .collection('words')
            .orderBy('createdAt', descending: true)
            .get();
      
        return wordsSnapshot.docs
            .map((doc) => Word.fromFirestore(doc))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      logger.e('語彙取得エラー: $e');
      rethrow;
    }
  }
}