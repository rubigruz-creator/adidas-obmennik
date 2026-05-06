import 'package:flutter/material.dart';

class BreadcrumbChips extends StatelessWidget {
  final List<Map<String, dynamic>> path;
  final Function(int? folderId, int index) onSelected;

  const BreadcrumbChips({
    Key? key,
    required this.path,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(Icons.home, size: 16),
            label: Text('Главная'),
            onPressed: () => onSelected(null, 0),
          ),
          ...path.asMap().entries.map((entry) {
            final index = entry.key;
            final folder = entry.value;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ActionChip(
                avatar: Icon(Icons.folder, size: 16, color: Colors.amber.shade700),
                label: Text(folder['name']),
                onPressed: () => onSelected(folder['id'], index + 1),
              ),
            );
          }),
        ],
      ),
    );
  }
}