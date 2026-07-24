import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/constants.dart';

class FriendService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    return await _authService.getToken();
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
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
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
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
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

    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
    return response.statusCode == 200;
  }

  Future<bool> acceptFriendRequest(int friendshipId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/friends/accept/$friendshipId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
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

    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
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
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
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

    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
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
    if (response.statusCode == 401) {
      AuthService.notifySessionExpired();
    }
    return null;
  }
}
