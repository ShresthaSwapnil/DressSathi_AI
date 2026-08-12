import 'package:dress_mate/screens/recommendation_screen.dart';
import 'package:dress_mate/services/recommendation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecommendationService extends Mock implements RecommendationService {}

void main() {
  testWidgets('white-box: manual weather generates a structured outfit', (
    tester,
  ) async {
    final service = MockRecommendationService();
    when(service.getSavedOutfits).thenAnswer((_) async => []);
    when(
      () => service.getOutfitRecommendation(
        occasion: any(named: 'occasion'),
        weather: any(named: 'weather'),
        useLiveWeather: any(named: 'useLiveWeather'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer(
      (_) async => {
        'title': 'Test outfit',
        'weather_summary': 'rainy',
        'model_used': 'mock-model',
        'items': <dynamic>[],
        'explanation': ['Layer safely'],
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: RecommendationScreen(service: service)),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Use live weather'));
    await tester.tap(find.text('Use live weather'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'rainy');
    await tester.ensureVisible(find.text('Generate outfit'));
    await tester.tap(find.text('Generate outfit'));
    await tester.pumpAndSettle();

    expect(find.text('Test outfit'), findsOneWidget);
    expect(find.text('• Layer safely'), findsOneWidget);
  });
}
