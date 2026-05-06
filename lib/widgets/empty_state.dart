import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    Key? key,
    this.message = 'В этой папке пусто\nНажмите «+» чтобы добавить файлы или папки',
    this.icon = Icons.folder_open,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}