import 'package:material_ui/material_ui.dart';

import '../welcome/welcome_screen.dart';

/// LearnTZ — Unified Welcome & Home Screen
/// Provides the single landing page combining former Welcome and Home interfaces.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
