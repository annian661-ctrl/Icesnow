import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:annian/main.dart';
import 'package:annian/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const IceSnowApp(),
      ),
    );
    expect(find.text('取链'), findsOneWidget);
  });
}
