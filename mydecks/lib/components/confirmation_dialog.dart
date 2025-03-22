import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool autoDismiss;
  
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.cancelText = 'キャンセル',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.autoDismiss = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final confirmColor = isDestructive 
        ? Colors.red 
        : theme.colorScheme.primary;
    
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            if (autoDismiss) {
              Navigator.of(context).pop();
            }
            onCancel?.call();
          },
          child: Text(cancelText),
        ),        
        TextButton(
          onPressed: () {
            if (autoDismiss) {
              Navigator.of(context).pop();
            }
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.white : null,
            backgroundColor: isDestructive ? confirmColor : null,
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDestructive ? Colors.white : confirmColor,
            ),
          ),
        ),
      ],
    );
  }
}