import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ApiService {
  static const String _baseUrl = 'https://gazonbaza.ru';

  static Future<Map<String, dynamic>> register(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'nickname': phone,
        'full_name': 'Пользователь',
        'position': 'Сотрудник',
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getFiles(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/list_files.php?type=all'),
      headers: {'X-API-Token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    return [];
  }

  static Future<bool> uploadFile(String token, File file, String fileName) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload.php'),
    );
    request.headers['X-API-Token'] = token;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['is_public'] = '1';

    final response = await request.send();
    return response.statusCode == 200;
  }

  static Future<bool> downloadFile(String token, int fileId, String fileName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/download.php?id=$fileId'),
      headers: {'X-API-Token': token},
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final Directory? downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        final savedFile = File('${downloadDir.path}/$fileName');
        await savedFile.writeAsBytes(bytes);
        await OpenFile.open(savedFile.path);
        return true;
      }
    }
    return false;
  }


  // ПЕРЕИМЕНОВАНИЕ ФАЙЛА
  static Future<bool> renameFile(String token, int fileId, String newName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rename.php'),
      headers: {
        'X-API-Token': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': fileId,
        'new_name': newName,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    }
    return false;
  }



  // НОВЫЙ МЕТОД - УДАЛЕНИЕ ФАЙЛА
  static Future<bool> deleteFile(String token, int fileId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/delete.php?id=$fileId'),
      headers: {'X-API-Token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    }
    return false;
  }
}