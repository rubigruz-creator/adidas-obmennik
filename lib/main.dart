import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(KusotschnitsaApp());
}

class KusotschnitsaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кусочница',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.orange),
      ),
      home: FileListPage(),
    );
  }
}

class FileListPage extends StatefulWidget {
  @override
  _FileListPageState createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  List<dynamic> _files = [];
  bool _isLoading = true;

  // ТВОИ ДАННЫЕ — ИСПРАВЛЕНО НА HTTPS
  final String _apiToken = '56822754785afd8ba3f22d46888f839c27ed675de16dd083f4945c1261ab85c3';
  final String _baseUrl = 'https://gazonbaza.ru';  // ← HTTPS!

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/list_files.php?type=all'),
        headers: {'X-API-Token': _apiToken},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _files = data['data']);
      } else {
        print('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload.php'),
    );
    request.headers['X-API-Token'] = _apiToken;
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      pickedFile.path,
    ));
    request.fields['is_public'] = '1';
    
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Файл загружен!')),
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Ошибка: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка загрузки: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Ошибка: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    final url = '$_baseUrl/download.php?id=$fileId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-API-Token': _apiToken},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📥 Файл $fileName скачан!')),
        );
        // TODO: сохранить файл на устройство
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка скачивания: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  Color _getColorForFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Colors.green;
    if (['pdf'].contains(ext)) return Colors.red;
    if (['doc', 'docx', 'txt'].contains(ext)) return Colors.blue;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Colors.purple;
    if (['mp3', 'wav'].contains(ext)) return Colors.pink;
    return Colors.orange;
  }

  void _showFileMenu(dynamic file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(file['original_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Размер: ${file['size_mb']} MB'),
            Text('Тип: ${file['file_type']}'),
            Text('Хозяин: ${file['owner_nickname']}'),
            Text('Дата: ${file['upload_date']}'),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _downloadFile(file['id'], file['original_name']),
              icon: Icon(Icons.download),
              label: Text('Скачать'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🍖 Кусочница'),
        actions: [
          IconButton(icon: Icon(Icons.cloud_upload), onPressed: _uploadFile),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadFiles),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(child: Text('Нет файлов. Нажми 📤 чтобы загрузить'))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final isRecent = index < 3;
                    final fontSize = isRecent ? 18.0 : 14.0;
                    final padding = isRecent ? 16.0 : 12.0;

                    return GestureDetector(
                      onTap: () => _showFileMenu(file),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                        decoration: BoxDecoration(
                          color: _getColorForFile(file['original_name']),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file['original_name'],
                                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${file['size_mb']} MB • ${file['owner_nickname']}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(file['is_public'] == 1 ? Icons.public : Icons.lock, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}