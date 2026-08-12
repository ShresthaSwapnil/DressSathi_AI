import 'package:dress_mate/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('white-box: bundled Lottie feedback assets render offline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              LottieStatus(
                asset: 'assets/animations/ai_thinking.json',
                title: 'Thinking',
                subtitle: 'Styling a look',
              ),
              LottieStatus(
                asset: 'assets/animations/uploading.json',
                title: 'Uploading',
                subtitle: 'Saving a piece',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Lottie), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
