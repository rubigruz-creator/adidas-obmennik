import 'package:flutter/material.dart';

class FileIcon extends StatelessWidget {
  final String fileType;
  final double size;

  const FileIcon({Key? key, required this.fileType, this.size = 48}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = fileType.toLowerCase();
    IconData icon;
    Color color;

    if (type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('webp') || type.contains('gif') || type.contains('bmp')) {
      icon = Icons.image;
      color = Colors.blue;
    } else if (type.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (type.contains('xls') || type.contains('xlsx') || type.contains('csv')) {
      icon = Icons.table_chart;
      color = Colors.green;
    } else if (type.contains('doc') || type.contains('docx') || type.contains('rtf')) {
      icon = Icons.description;
      color = Colors.indigo;
    } else if (type.contains('zip') || type.contains('rar') || type.contains('7z') || type.contains('tar') || type.contains('gz')) {
      icon = Icons.archive;
      color = Colors.brown;
    } else if (type.contains('mp3') || type.contains('wav') || type.contains('flac') || type.contains('ogg')) {
      icon = Icons.audio_file;
      color = Colors.purple;
    } else if (type.contains('mp4') || type.contains('avi') || type.contains('mkv') || type.contains('mov')) {
      icon = Icons.video_file;
      color = Colors.orange;
    } else if (type.contains('txt') || type.contains('log') || type.contains('md')) {
      icon = Icons.text_snippet;
      color = Colors.teal;
    } else if (type.contains('htm') || type.contains('php') || type.contains('dart') || type.contains('js') || type.contains('py')) {
      icon = Icons.code;
      color = Colors.cyan;
    } else if (type.contains('apk')) {
      icon = Icons.android;
      color = Colors.green;
    } else if (type.contains('cdr')) {
      icon = Icons.design_services;
      color = Colors.orange;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}