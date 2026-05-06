import 'package:intl/intl.dart';

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${NumberFormat('#.#').format(kb)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${NumberFormat('#.#').format(mb)} MB';
  final gb = mb / 1024;
  return '${NumberFormat('#.#').format(gb)} GB';
}