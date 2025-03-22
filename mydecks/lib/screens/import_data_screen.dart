import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_voice_tutor/repositories/storage_repository.dart';
import 'package:path/path.dart' as path;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final importDataStateProvider = StateNotifierProvider<ImportDataNotifier, ImportDataState>((ref) {
  return ImportDataNotifier();
});

class ImportDataState {
  final bool isUpLoading;
  final double uploadProgress;
  final String? errorMessage;
  
  const ImportDataState({
    this.isUpLoading = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
  });

  ImportDataState copyWith({
    bool? isUpLoading,
    double? uploadProgress,
    String? errorMessage,
  }) {
    return ImportDataState(
      isUpLoading: isUpLoading ?? this.isUpLoading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
    );
  }
}

class ImportDataNotifier extends StateNotifier<ImportDataState> {
  ImportDataNotifier() : super(const ImportDataState());
  
  void startProcess() {
    state = state.copyWith(isUpLoading: true, errorMessage: null);
  }
  
  void processSuccess() {
    state = state.copyWith(isUpLoading: false);
  }
  
  void processError(String message) {
    state = state.copyWith(isUpLoading: false, errorMessage: message);
  }

  void updateUploadProgress(double uploadProgress) {
    state = state.copyWith(uploadProgress: uploadProgress);
  }
}

class ImportDataScreen extends ConsumerStatefulWidget {
  final String path;
  final SharedMediaType type;

  const ImportDataScreen({
    super.key,
    required this.path,
    required this.type,
  });

  @override
  ConsumerState<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends ConsumerState<ImportDataScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _fileType = '';

  @override
  void initState() {
    super.initState();
    _detectFileType();
  }
  

  void _detectFileType() {
    debugPrint(widget.type.value);
    setState(() {
      switch (widget.type.value) {
        case 'image':
          _fileType = 'image';
          break;
        case 'video':
          _fileType = 'video';
          break;
        case 'text':
          _fileType = 'text';
          break;
        case 'url':
          _fileType = 'url';
          break;
        case 'file':
        default:
          switch (path.extension(widget.path).toLowerCase()) {
            case '.mp3':
            case '.m4a':
            case '.wav':
            case '.aac':
            case '.flac':
            case '.ogg':
              _fileType = 'audio';
              break;
            case '.txt':
              _fileType = 'text';
              break;
            case '.doc':
            case '.docx':
            case '.pdf':
              _fileType = 'document';
              break;
            case '.jpg':
            case '.jpeg':
            case '.png':
            case '.gif':
              _fileType = 'image';
              break;
            default:
              _fileType = 'unknown';
          }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processAndContinue() async {
    final l10n = AppLocalizations.of(context)!;

    final notifier = ref.read(importDataStateProvider.notifier);
    final storageService = ref.read(firebaseStorageRepositoryProvider);
    notifier.startProcess();
    
    try {
      if (widget.type.value == 'text' || widget.type.value == 'url') {
        await storageService.uploadText(
          text: widget.path,
          fileType: _fileType,
          title: _titleController.text,
          notes: _notesController.text,
          onProgress: _updateUploadProgress,
        );
      } else {
        // oridinal file
        await storageService.uploadFile(
          file: File(widget.path),
          fileType: _fileType,
          title: _titleController.text,
          notes: _notesController.text,
          onProgress: _updateUploadProgress,
        );
      }

      notifier.processSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('アップロードが完了しました！'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 16.0, right: 16.0, left: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.go('/decks');
      }
    } catch (e) {
      notifier.processError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('${l10n.fileImportError}: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 16.0, right: 16.0, left: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _updateUploadProgress(double progress) {
    if (context.mounted) {
      if (progress.isNaN || progress.isInfinite) {
        progress = 0.0;
      }
      progress = progress.clamp(0.0, 1.0);
      final notifier = ref.read(importDataStateProvider.notifier);
      notifier.updateUploadProgress(progress);
    }
  }

  IconData _getFileTypeIcon() {
    if (widget.type.value == 'url') {
      return Icons.link;
    } else if (widget.type.value == 'video') {
      return Icons.video_file;
    } else if (widget.type.value == 'text') {
      return Icons.text_snippet;
    }
    
    switch (_fileType) {
      case 'audio':
        return Icons.audio_file;
      case 'document':
        return Icons.description;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (widget.type.value == 'url') {
      return Colors.indigo.shade400;
    } else if (widget.type.value == 'video') {
      return Colors.red.shade400;
    } else if (widget.type.value == 'text') {
      return Colors.amber.shade700;
    }
    
    switch (_fileType) {
      case 'audio':
        return Colors.purple.shade400;
      case 'document':
        return Colors.blue.shade400;
      case 'image':
        return Colors.green.shade400;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final importState = ref.watch(importDataStateProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.importFile),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ファイル情報',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildFileInfo(),
              const SizedBox(height: 32),
              
              Text(
                '単語帳情報',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildMetadataInput(),
              const SizedBox(height: 40),
              
              // 続行ボタン
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: importState.isUpLoading ? null : _processAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    elevation: 4,
                    shadowColor: theme.colorScheme.secondary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: importState.isUpLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24, 
                              height: 24,
                              child: CircularProgressIndicator(
                                value: importState.uploadProgress.isFinite ? importState.uploadProgress : null,
                                color: theme.colorScheme.onSecondary,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'アップロード中... ${(importState.uploadProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text(
                              l10n.continueToProcessing,
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              if (importState.errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          importState.errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    final theme = Theme.of(context);
    final fileTypeColor = _getFileTypeColor();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: fileTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileTypeIcon(),
                  size: 36,
                  color: fileTypeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type.value == 'text' 
                          ? 'テキストデータ' 
                          : widget.type.value == 'url'
                              ? Uri.parse(widget.path).host
                              : widget.path,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: fileTypeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _fileType.toUpperCase(),
                            style: TextStyle(
                              color: fileTypeColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        if (widget.type.value == 'url') 
                          Expanded(
                            child: Text(
                              widget.path,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataInput() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: '単語帳タイトル（オプション）',
            hintText: '単語帳のタイトルを入力 (空白の場合は自動生成されます)',
            prefixIcon: Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        
        const SizedBox(height: 20),
        
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: '単語帳メモ（オプション）',
            hintText: '単語帳に関するメモを入力',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 65),
              child: Icon(Icons.note),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}