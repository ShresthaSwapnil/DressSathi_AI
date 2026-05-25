import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class FriendService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<List<dynamic>?> getFriends() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/friends/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<List<dynamic>?> getFriendRequests() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/friends/requests'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<bool> sendFriendRequest(String email) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/friends/request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'addressee_email': email}),
    );

    return response.statusCode == 200;
  }

  Future<bool> acceptFriendRequest(int friendshipId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/friends/accept/$friendshipId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // ── Shared Outfits ──
  Future<bool> shareOutfit(int outfitId, int friendUserId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/outfits/$outfitId/share'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'friend_user_id': friendUserId}),
    );

    return response.statusCode == 200;
  }

  Future<List<dynamic>?> getSharedOutfits() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/outfits/shared'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  // ── Feedback ──
  Future<bool> postComment(int sharedOutfitId, String comment) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/feedback/$sharedOutfitId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'comment': comment}),
    );

    return response.statusCode == 200;
  }

  Future<List<dynamic>?> getComments(int sharedOutfitId) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/feedback/$sharedOutfitId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
