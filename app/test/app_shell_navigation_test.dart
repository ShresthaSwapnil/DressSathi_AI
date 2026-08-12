import 'package:dress_mate/main.dart';
import 'package:dress_mate/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'white-box: backward navigation fully fades the previous screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: MaterialApp(home: const AppShell()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('You'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Wardrobe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final previous = tester.renderObject<RenderAnimatedOpacity>(
        find.byKey(const ValueKey('screen-opacity-3')),
      );
      final current = tester.renderObject<RenderAnimatedOpacity>(
        find.byKey(const ValueKey('screen-opacity-0')),
      );
      expect(previous.opacity.value, 0);
      expect(current.opacity.value, 1);
    },
  );
}
