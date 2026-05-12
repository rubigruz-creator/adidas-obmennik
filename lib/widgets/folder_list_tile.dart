import 'package:flutter/material.dart';

class FolderListTile extends StatelessWidget {
  final Map<String, dynamic> folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  // ─── Новые поля для режима выбора ─────────────────────────────
  final bool isSelectionMode;
  final bool isSelected;

  const FolderListTile({
    Key? key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Чекбокс или иконка папки
              if (isSelectionMode)
                Container(
                  width: 36,
                  height: 36,
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
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 22)
                      : null,
                )
              else
                Icon(Icons.folder, size: 36, color: Colors.amber.shade700),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  folder['name'] ?? 'Папка',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isSelectionMode)
                Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
      // Цвет выделения для ListTile-стиля
      // (используем ColoredBox внутри Card, т.к. это не ListTile)
    );
  }
}