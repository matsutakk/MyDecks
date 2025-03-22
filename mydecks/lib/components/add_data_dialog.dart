import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

class AddDataDialog extends ConsumerWidget {
  const AddDataDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(l10n.addContent),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(context, l10n.importExisting),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildImportOption(
                    context,
                    icon: Icons.audio_file,
                    label: l10n.audio,
                    fileType: FileType.any,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImportOption(
                    context,
                    icon: Icons.description,
                    label: l10n.document,
                    fileType: FileType.any,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImportOption(
                    context,
                    icon: Icons.image,
                    label: l10n.image,
                    fileType: FileType.image,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
  
  Widget _buildImportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required FileType fileType,
    List<String>? allowedExtensions,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => _pickFile(context, fileType, allowedExtensions),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(
    BuildContext context, 
    FileType fileType, 
    List<String>? allowedExtensions
  ) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : fileType,
        allowMultiple: false,
        allowedExtensions: allowedExtensions,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {          
          if (context.mounted) {
            Navigator.of(context).pop();
            context.go('/import_data', extra: {
              'path': file.path,
            });
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.fileSelectionError}: $e')),
        );
      }
    }
  }
}