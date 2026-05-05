import 'package:flutter/material.dart';

class FilePill extends StatelessWidget {
  final Map<String, dynamic> file;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FilePill({
    Key? key,
    required this.file,
    required this.index,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = 16.0 - (index * 0.2).clamp(0.0, 4.0);
    final double padding = 12.0 - (index * 0.5).clamp(0.0, 4.0);
    
    // Определяем цвет в зависимости от типа файла
    Color getFileColor() {
      final String type = file['file_type']?.toLowerCase() ?? '';
      if (type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('webp')) {
        return Colors.green.shade100;
      } else if (type.contains('pdf')) {
        return Colors.red.shade100;
      } else if (type.contains('txt')) {
        return Colors.blue.shade100;
      } else if (type.contains('http') || type.contains('php') || type.contains('dart')) {
        return Colors.purple.shade100;
      } else {
        return Colors.grey.shade200;
      }
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: getFileColor(),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
          child: Row(
            children: [
              Icon(
                file['is_public'] == 1 ? Icons.public : Icons.lock,
                size: 18,
                color: file['is_public'] == 1 ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['original_name'],
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${file['size_mb']} MB • ${file['owner_nickname']}',
                      style: TextStyle(fontSize: fontSize - 4, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}