import 'package:cloud_firestore/cloud_firestore.dart';

class SynonymOrAntonym {
  final String word;

  SynonymOrAntonym({required this.word});

  factory SynonymOrAntonym.fromMap(Map<String, dynamic> map) {
    return SynonymOrAntonym(word: map['word'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'word': word};
  }
}

class Collocation {
  final String phrase;
  final String translation;
  final String example;

  Collocation({
    required this.phrase,
    required this.translation,
    required this.example,
  });

  factory Collocation.fromMap(Map<String, dynamic> map) {
    return Collocation(
      phrase: map['phrase'] ?? '',
      translation: map['translation'] ?? '',
      example: map['example'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phrase': phrase,
      'translation': translation,
      'example': example,
    };
  }
}

class Word {
  final String id;
  final String word;
  final Map<String, String> definition;
  final List<Map<String, String>> examples;
  final List<SynonymOrAntonym> synonyms;
  final List<SynonymOrAntonym> antonyms;
  final List<Collocation> collocations;
  final DateTime createdAt;
  final String difficulty;
  final String source;
  final String nativeLanguage;
  final String targetLanguage;

  Word({
    required this.id,
    required this.word,
    required this.definition,
    required this.examples,
    this.synonyms = const [],
    this.antonyms = const [],
    this.collocations = const [],
    required this.createdAt,
    required this.difficulty,
    required this.source,
    required this.nativeLanguage,
    required this.targetLanguage,
  });

  factory Word.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert definition map to correct type
    final Map<String, String> typedDefinition = {};
    if (data['definition'] != null) {
      final rawDefinition = data['definition'] as Map<String, dynamic>;
      rawDefinition.forEach((key, value) {
        typedDefinition[key] = value.toString();
      });
    }
    
    // Convert examples to correct type
    final List<Map<String, String>> typedExamples = [];
    if (data['examples'] != null) {
      final rawExamples = data['examples'] as List<dynamic>;
      typedExamples.addAll(rawExamples.map((example) {
        final Map<String, String> typedExample = {};
        if (example is Map<String, dynamic>) {
          example.forEach((key, value) {
            typedExample[key] = value.toString();
          });
        }
        return typedExample;
      }).toList());
    }
    
    // Convert synonyms
    final List<SynonymOrAntonym> typedSynonyms = [];
    if (data['synonyms'] != null) {
      final rawSynonyms = data['synonyms'] as List<dynamic>;
      typedSynonyms.addAll(rawSynonyms.map((synonym) {
        return SynonymOrAntonym.fromMap(synonym as Map<String, dynamic>);
      }).toList());
    }
    
    // Convert antonyms
    final List<SynonymOrAntonym> typedAntonyms = [];
    if (data['antonyms'] != null) {
      final rawAntonyms = data['antonyms'] as List<dynamic>;
      typedAntonyms.addAll(rawAntonyms.map((antonym) {
        return SynonymOrAntonym.fromMap(antonym as Map<String, dynamic>);
      }).toList());
    }
    
    // Convert collocations
    final List<Collocation> typedCollocations = [];
    if (data['collocations'] != null) {
      final rawCollocations = data['collocations'] as List<dynamic>;
      typedCollocations.addAll(rawCollocations.map((collocation) {
        return Collocation.fromMap(collocation as Map<String, dynamic>);
      }).toList());
    }
    
    return Word(
      id: doc.id,
      word: data['word'] ?? '',
      definition: typedDefinition,
      examples: typedExamples,
      synonyms: typedSynonyms,
      antonyms: typedAntonyms,
      collocations: typedCollocations,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      difficulty: data['difficulty'] ?? 'intermediate',
      source: data['sourceSet'] ?? '',
      nativeLanguage: data['nativeLanguage'] ?? '',
      targetLanguage: data['targetLanguage'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'definition': definition,
      'examples': examples,
      'synonyms': synonyms.map((s) => s.toMap()).toList(),
      'antonyms': antonyms.map((a) => a.toMap()).toList(),
      'collocations': collocations.map((c) => c.toMap()).toList(),
      'difficulty': difficulty,
      'source': source,
      'nativeLanguage': nativeLanguage,
      'targetLanguage': targetLanguage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}