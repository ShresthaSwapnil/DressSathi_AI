import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dress_mate/screens/login_screen.dart';
import 'package:dress_mate/providers/auth_provider.dart';

void main() {
  testWidgets('LoginScreen renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Verify that the login screen renders key elements
    expect(find.text('DressMate'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
