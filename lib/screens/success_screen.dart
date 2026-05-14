import 'package:flutter/material.dart';
import '../utils/style_constants.dart';
import '../widgets/premium_ui.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String message;
  const SuccessScreen({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const ConfettiCelebration(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AshallTheme.successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AshallTheme.successColor, size: 100),
                  ),
                  const SizedBox(height: 40),
                  Text(title, style: AshallTheme.displayStyle.copyWith(fontSize: 28)),
                  const SizedBox(height: 15),
                  Text(message, textAlign: TextAlign.center, style: AshallTheme.subtitleStyle),
                  const SizedBox(height: 60),
                  PremiumButton(
                    text: "العودة للتسوق",
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

