import 'package:flutter/material.dart';

class FolderPill extends StatelessWidget {
  final Map<String, dynamic> folder;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FolderPill({
    Key? key,
    required this.folder,
    required this.index,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = 16.0 - (index * 0.2).clamp(0.0, 4.0);
    final double padding = 12.0 - (index * 0.5).clamp(0.0, 4.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
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
              Icon(Icons.folder, color: Colors.amber.shade800),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder['name'],
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}