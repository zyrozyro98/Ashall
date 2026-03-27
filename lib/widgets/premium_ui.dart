import 'package:flutter/material.dart';
import '../utils/style_constants.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const PremiumButton({super.key, required this.text, required this.onPressed, this.isLoading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 60,
        decoration: AshallTheme.buttonDecoration,
        alignment: Alignment.center,
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, color: Colors.white, size: 24),
                if (icon != null) const SizedBox(width: 8),
                Text(text, style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 18)),
              ],
            ),
      ),
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? icon;

  const PremiumTextField({super.key, required this.label, required this.controller, this.isPassword = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // 0.04 * 255 approx 10
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: AshallTheme.bodyStyle,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AshallTheme.subtitleStyle,
          prefixIcon: icon != null ? Icon(icon, color: AshallTheme.primaryColor) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
