import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

abstract class StorageRepository {
  Future<String> uploadFile({
    required File file,
    String? fileType,
    String? title,
    String? notes,
    Function(double)? onProgress,
  });
  
  Future<void> deleteFile(String fileUrl);
  
  Future<String> uploadText({
    required String text,
    String? fileType,
    String? title,
    String? notes,
    String extension,
    Function(double)? onProgress,
  });
  
  Future<Map<String, dynamic>> getFileMetadata(String fileUrl);
}

final firebaseStorageRepositoryProvider = Provider<FirebaseStorageImpl>((ref) {
  return FirebaseStorageImpl();
});

class FirebaseStorageImpl implements StorageRepository  {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required File file,
    String? fileType,
    String? title,
    String? notes,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final extension = path.extension(fileName).toLowerCase();
      
      final uuid = const Uuid().v4();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final storagePath = 'users/$userId/files/$uuid$extension';

      final storageRef = _storage.ref().child(storagePath);

      final contentType = _getContentType(extension);

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'title': title ?? '',
          'notes': notes ?? '',
          'fileType': fileType ?? 'file',
          'originalFileName': fileName,
          'uploadDate': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putFile(file, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  @override
  Future<String> uploadText({
    required String text,
    String? fileType,
    String? title,
    String? notes,
    String extension = '.txt',
    Function(double)? onProgress,
  }) async {
    try {
      final bytes = utf8.encode(text);
      final data = Uint8List.fromList(bytes);
      final uuid = const Uuid().v4();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final storagePath = 'users/$userId/files/$uuid$extension';
      final storageRef = _storage.ref().child(storagePath);
      final contentType = _getContentType(extension);

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'title': title ?? '',
          'notes': notes ?? '',
          'fileType': fileType ?? '',
          'originalFileName': '$title$extension',
          'uploadDate': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putData(data, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload text: $e');
    }
  }

  Future<Map<String, dynamic>> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      
      return metadata.customMetadata ?? {};
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }

  String _getContentType(String extension) {
    switch (extension) {
      case '.mp3': case '.m4a': case '.wav': case '.aac': case '.flac': case '.ogg':
        return 'audio/${extension.replaceFirst('.', '')}';
      case '.txt': case '.doc': case '.docx': case '.pdf':
        return 'application/${extension.replaceFirst('.', 'pdf')}';
      case '.jpg': case '.jpeg': case '.png': case '.gif':
        return 'image/${extension.replaceFirst('.', '')}';
      case '.mp4': case '.avi': case '.mov': case '.mkv':
        return 'video/${extension.replaceFirst('.', '')}';
      default:
        return 'application/octet-stream';
    }
  }
}
