import 'package:flutter/material.dart';
import '../utils/format_file_size.dart';
import '../utils/format_date.dart';
import 'file_icon.dart';

class FileListTile extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  // ─── Новые поля для режима выбора ─────────────────────────────
  final bool isSelectionMode;
  final bool isSelected;

  const FileListTile({
    Key? key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNew = file['is_new'] == true;
    return ListTile(
      leading: Stack(
        children: [
          // В режиме выбора показываем чекбокс вместо иконки
          if (isSelectionMode)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 24)
                  : null,
            )
          else ...[
            FileIcon(fileType: file['file_type'] ?? '', size: 40),
            if (isNew)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ],
      ),
      title: Text(file['original_name'] ?? 'Без имени', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatFileSize(file['file_size'] ?? 0)),
      trailing: Text(formatRelativeDate(file['upload_date'] ?? '')),
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    );
  }
}