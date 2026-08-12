import 'dart:convert';

import 'package:dress_mate/services/auth_service.dart';
import 'package:dress_mate/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockClient extends Mock implements http.Client {}

void main() {
  late MockAuthService auth;
  late MockClient client;
  late RecommendationService service;

  setUpAll(() => registerFallbackValue(Uri.parse('http://localhost')));

  setUp(() {
    auth = MockAuthService();
    client = MockClient();
    service = RecommendationService(authService: auth, client: client);
    when(() => auth.headers(json: true)).thenAnswer(
      (_) async => {
        'Authorization': 'Bearer test',
        'Content-Type': 'application/json',
      },
    );
  });

  test('white-box: posts structured recommendation inputs', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'title': 'Office layers',
          'occasion': 'work',
          'weather_summary': 'cool',
          'items': [],
          'explanation': ['Comfortable'],
          'provider': 'gemini',
          'model_used': 'test',
          'items_analyzed': 2,
        }),
        200,
      ),
    );

    final result = await service.getOutfitRecommendation(
      occasion: 'work',
      weather: 'cool',
      useLiveWeather: false,
    );

    expect(result?['title'], 'Office layers');
    final call =
        verify(
              () => client.post(
                any(),
                headers: any(named: 'headers'),
                body: captureAny(named: 'body'),
                encoding: any(named: 'encoding'),
              ),
            ).captured.single
            as String;
    final body = jsonDecode(call) as Map<String, dynamic>;
    expect(body['occasion'], 'work');
    expect(body['use_live_weather'], isFalse);
  });
}
