import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String title;
  final String description;
  final String fileType;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.fileType,
    required this.wordCount,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  static Future<Deck> fromFirestoreWithWordCount(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    // Get the words subcollection reference
    final wordsCollectionRef = FirebaseFirestore.instance
        .collection('decks')
        .doc(doc.id)
        .collection('words');
    
    // Get the subcollection count
    final QuerySnapshot wordsSnapshot = await wordsCollectionRef.get();
    final int wordsCount = wordsSnapshot.size;
    
    return Deck(
      id: doc.id,
      title: data['title'] ?? '作成中',
      description: data['description'] ?? '',
      fileType: data['fileType'] ?? '',
      wordCount: wordsCount,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }
}