import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ItemService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>?> getItems() async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/items/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<String?> uploadImage(XFile imageFile) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.baseUrl}/items/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> createItem({
    required String imageUrl,
    String? name,
    String? category,
    String? color,
    String? style,
    String? season,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/items/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image_url': imageUrl,
        'name': name,
        'category': category,
        'color': color,
        'style': ?style,
        'season': ?season,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateItem(
    int itemId, {
    String? name,
    String? category,
    String? color,
    String? style,
    String? season,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (color != null) body['color'] = color;
    if (style != null) body['style'] = style;
    if (season != null) body['season'] = season;

    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/items/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> deleteItem(int itemId) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/items/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> analyzeImage(XFile imageFile) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.baseUrl}/items/analyze'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
