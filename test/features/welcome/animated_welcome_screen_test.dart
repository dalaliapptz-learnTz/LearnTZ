import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/welcome/welcome_screen.dart';
import 'package:learntz/features/welcome/widgets/animated_welcome_emblem.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';

Widget _buildTestApp({Widget? child}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child ?? const WelcomeScreen(),
      ),
    ),
  );
}

void main() {
  group('Animated Welcome Screen', () {
    testWidgets('renders animated emblem and welcome typography', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AnimatedWelcomeEmblem), findsOneWidget);
      expect(find.text('Learning that moves with your child.'), findsOneWidget);
      expect(find.text('Learn Anywhere, Anytime'), findsWidgets);
      expect(find.text('Skip to Country'), findsOneWidget);

      // Fast-forward animation sequence to completion
      await tester.pumpAndSettle();

      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('TZ'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AnimatedWelcomeEmblem animates through all stages without exception', (
      tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedWelcomeEmblem(
                size: 240,
                onSequenceCompleted: () => completed = true,
              ),
            ),
          ),
        ),
      );

      // 1. Initial frame
      await tester.pump();
      expect(completed, isFalse);

      // 2. Step 1: Logo fade & scale (700 ms)
      await tester.pump(const Duration(milliseconds: 700));

      // 3. Step 2: Cap drop (600 ms)
      await tester.pump(const Duration(milliseconds: 600));

      // 4. Step 3: Golden rays (800 ms)
      await tester.pump(const Duration(milliseconds: 800));

      // 5. Step 4: Book opens (700 ms)
      await tester.pump(const Duration(milliseconds: 700));

      // 6. Step 5: Sparkles appear (900 ms)
      await tester.pump(const Duration(milliseconds: 900));

      // 7. Step 6: Typography reveal (700 ms)
      await tester.pump(const Duration(milliseconds: 700));

      // 8. Step 7: Tagline slide & completion (600 ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
