import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/constants.dart';

class RecommendationService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<Map<String, dynamic>?> getOutfitRecommendation({
    String occasion = 'casual',
    String weather = 'clear',
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(
          '${Constants.baseUrl}/recommendations/outfit?occasion=$occasion&weather=$weather'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
    return null;
  }

  Future<Map<String, dynamic>?> saveOutfit({
    required String recommendationText,
    String? occasion,
    String? weather,
    String? itemIds,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/outfits/save'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'recommendation_text': recommendationText,
        'occasion': occasion,
        'weather': weather,
        'item_ids': itemIds,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
    return null;
  }

  Future<List<dynamic>?> getSavedOutfits() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/outfits/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
    return null;
  }

  Future<bool> deleteOutfit(int outfitId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/outfits/$outfitId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
    return response.statusCode == 200;
  }
}
