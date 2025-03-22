import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_voice_tutor/providers/app_router_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SupportedFileTypes {
  static const List<String> audio = ['.mp3', '.m4a', '.wav', '.aac', '.flac', '.ogg'];
  static const List<String> image = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];
  static const List<String> document = ['.txt', '.pdf', '.doc', '.docx', '.csv', '.rtf'];
  
  static bool isAudio(String extension) => audio.contains(extension.toLowerCase());
  static bool isImage(String extension) => image.contains(extension.toLowerCase());
  static bool isDocument(String extension) => document.contains(extension.toLowerCase());
  static bool isSupported(String extension) => 
      isAudio(extension) || isImage(extension) || isDocument(extension);
}

final sharedFilesHandlerProvider = Provider((ref) => SharedFilesHandler(ref: ref));

class SharedFilesHandler {
  final Ref ref;
  StreamSubscription? _intentDataStreamSubscription;
  
  SharedFilesHandler({required this.ref});
  
  void initSharedContentListener() {
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleSharedFiles);
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream()
        .listen(_handleSharedFiles, onError: (err) {
      debugPrint("Error receiving shared files: $err");
    });
  }
  
  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final sharedFile = files.first;
    final router = ref.watch(routerProvider);
    router.go('/import_data', extra: {
      'path': sharedFile.path,
      'type': sharedFile.type,
    });
  }
  
  
  void resetSharedContent() {
    ReceiveSharingIntent.instance.reset();
  }
  
  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}