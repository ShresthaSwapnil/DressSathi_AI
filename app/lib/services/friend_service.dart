import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'auth_service.dart';

class FriendService {
  FriendService({AuthService? authService, http.Client? client})
    : _authService = authService ?? AuthService(),
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<http.Response?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _authService.headers(json: body != null);
      if (headers == null) return null;
      final request = http.Request(
        method,
        Uri.parse('${Constants.baseUrl}$path'),
      )..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      return http.Response.fromStream(await _client.send(request));
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> _list(String path) async {
    final response = await _request('GET', path);
    return response?.statusCode == 200
        ? jsonDecode(response!.body) as List<dynamic>
        : [];
  }

  Future<bool> _success(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _request(method, path, body: body);
    return response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300;
  }

  Future<List<dynamic>> getFriends() => _list('/friends/');
  Future<List<dynamic>> searchUsers(String query) =>
      _list('/friends/search?q=${Uri.encodeQueryComponent(query.trim())}');
  Future<List<dynamic>> getFriendRequests() => _list('/friends/requests');
  Future<List<dynamic>> getSentRequests() => _list('/friends/requests/sent');

  Future<bool> sendFriendRequest(String email) => _success(
    'POST',
    '/friends/request',
    body: {'addressee_email': email.trim()},
  );
  Future<bool> acceptFriendRequest(int id) =>
      _success('POST', '/friends/accept/$id');
  Future<bool> rejectFriendRequest(int id) =>
      _success('POST', '/friends/reject/$id');
  Future<bool> cancelFriendRequest(int id) =>
      _success('DELETE', '/friends/request/$id');
  Future<bool> removeFriend(int id) => _success('DELETE', '/friends/$id');

  Future<List<dynamic>> getSharedOutfits() => _list('/outfits/shared');
  Future<bool> shareOutfit(int outfitId, int friendUserId) => _success(
    'POST',
    '/outfits/$outfitId/share',
    body: {'friend_user_id': friendUserId},
  );

  Future<List<dynamic>> getFeedbackRequests({String box = 'inbox'}) =>
      _list('/feedback/requests?box=$box');
  Future<bool> requestFeedback({
    required int recipientId,
    List<int> itemIds = const [],
    int? outfitId,
    String? message,
  }) => _success(
    'POST',
    '/feedback/requests',
    body: {
      'recipient_id': recipientId,
      'item_ids': itemIds,
      'outfit_id': ?outfitId,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    },
  );
  Future<bool> respondToFeedback(
    int requestId, {
    int? rating,
    String? comment,
  }) => _success(
    'POST',
    '/feedback/requests/$requestId/respond',
    body: {
      'rating': ?rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    },
  );

  Future<List<dynamic>> getNotifications() => _list('/notifications');
  Future<bool> readAllNotifications() =>
      _success('POST', '/notifications/read-all');

  Future<List<dynamic>> getWardrobeShares({String box = 'received'}) =>
      _list('/wardrobe-shares?box=$box');
  Future<List<dynamic>> getSharedWardrobeItems(int shareId) =>
      _list('/wardrobe-shares/$shareId/items');
  Future<bool> shareWardrobe(
    int friendUserId, {
    List<int> itemIds = const [],
  }) => _success(
    'POST',
    '/wardrobe-shares',
    body: {'friend_user_id': friendUserId, 'item_ids': itemIds},
  );
  Future<bool> revokeWardrobeShare(int shareId) =>
      _success('DELETE', '/wardrobe-shares/$shareId');
}
