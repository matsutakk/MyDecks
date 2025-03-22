import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Future<Map<String, dynamic>> getUserStats();
  Future<Map<String, dynamic>> getUserLanguageSettings();
  Future<void> updateUserLanguage({String? nativeLanguage, String? targetLanguage});
}

class UserRepositoryImpl implements UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      return user;
    } catch (e) {
      debugPrint('Googleサインインエラー: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
        
    try {
      final decksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .get();
      
      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userSnapshot.data();
      int totalWords = 0;
      if (userData != null && userData.containsKey('stats')) {
        final stats = userData['stats'];
        if (stats != null && stats is Map<String, dynamic> && stats.containsKey('totalWords')) {
          final rawTotalWords = stats['totalWords'];
          if (rawTotalWords != null) {
            if (rawTotalWords is int) {
              totalWords = rawTotalWords;
            } else if (rawTotalWords is double) {
              totalWords = rawTotalWords.toInt();
            }
          }
        }
      }
      return {
        'date': today.toIso8601String(),
        'deckCount': decksSnapshot.docs.length,
        'totalWords': totalWords.toString(),
      };
    } catch (e) {
      return {
        'date': today.toIso8601String(),
        'deckCount': 0,
        'totalWords': 0,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getUserLanguageSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      return {
        'nativeLanguage': docSnapshot.data()?['nativeLanguage'] ?? 'ja',
        'targetLanguage': docSnapshot.data()?['targetLanguage'] ?? 'en',
      };
    } catch (e) {
      throw Exception('Failed to get language settings: $e');
    }
  }

  @override
  Future<void> updateUserLanguage({String? nativeLanguage, String? targetLanguage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final Map<String, dynamic> updates = {};
      if (nativeLanguage != null) updates['nativeLanguage'] = nativeLanguage;
      if (targetLanguage != null) updates['targetLanguage'] = targetLanguage;

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update language settings: $e');
    }
  }
}