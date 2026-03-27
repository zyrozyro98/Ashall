import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_yupep9sn.json', // Checkmark animation
                width: 250,
                height: 250,
                repeat: false,
              ),
              const SizedBox(height: 30),
              Text(title, style: AshallTheme.titleStyle.copyWith(fontSize: 26)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: AshallTheme.subtitleStyle),
              const SizedBox(height: 50),
              PremiumButton(
                text: "العودة للرئيسية",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
