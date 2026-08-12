import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'auth_service.dart';

class RecommendationService {
  RecommendationService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<Map<String, dynamic>?> getOutfitRecommendation({
    String occasion = 'casual',
    String weather = 'clear',
    bool useLiveWeather = true,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _authService.headers(json: true);
      if (headers == null) return null;
      final response = await _client
          .post(
            Uri.parse('${Constants.baseUrl}/recommendations'),
            headers: headers,
            body: jsonEncode({
              'occasion': occasion,
              'manual_weather': weather,
              'use_live_weather': useLiveWeather,
              'latitude': ?latitude,
              'longitude': ?longitude,
            }),
          )
          .timeout(const Duration(seconds: 45));
      return response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveOutfit(
    Map<String, dynamic> recommendation,
  ) async {
    try {
      final headers = await _authService.headers(json: true);
      if (headers == null) return null;
      final items = (recommendation['items'] as List<dynamic>? ?? []);
      final reasons = <String, String>{
        for (final item in items)
          '${item['clothing_item_id']}': '${item['reason'] ?? ''}',
      };
      final response = await _client.post(
        Uri.parse('${Constants.baseUrl}/outfits/save'),
        headers: headers,
        body: jsonEncode({
          'title': recommendation['title'],
          'occasion': recommendation['occasion'],
          'weather': recommendation['weather_summary'],
          'recommendation_text':
              (recommendation['explanation'] as List<dynamic>? ?? []).join(' '),
          'item_ids': items.map((item) => item['clothing_item_id']).toList(),
          'reasons': reasons,
          'provider': recommendation['provider'],
          'model_used': recommendation['model_used'],
          'confidence_score': recommendation['confidence_score'],
        }),
      );
      return response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>?> getSavedOutfits() async {
    try {
      final headers = await _authService.headers();
      if (headers == null) return null;
      final response = await _client.get(
        Uri.parse('${Constants.baseUrl}/outfits/'),
        headers: headers,
      );
      return response.statusCode == 200
          ? jsonDecode(response.body) as List<dynamic>
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteOutfit(int outfitId) async {
    try {
      final headers = await _authService.headers();
      if (headers == null) return false;
      final response = await _client.delete(
        Uri.parse('${Constants.baseUrl}/outfits/$outfitId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
