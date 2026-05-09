import 'package:flutter/material.dart';
import 'chat_screen.dart';

class AiTriageScreen extends StatelessWidget {
  const AiTriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This serves as the root screen for the AI tab
    // We simply embed the ChatScreen pre-configured for the AI Assistant.
    // Because it's within a StatefulNavigationShell, the chat state will be preserved
    // when switching tabs.
    return const ChatScreen(
      name: 'IA Nexora',
      initials: 'IA',
      color: Color(0xFF6366F1), // AppColors.primary
      subtitle: 'Intelligence Artificielle',
      online: true,
      isAi: true,
      // No conversationId initially, the chat provider handles starting a new one
    );
  }
}
